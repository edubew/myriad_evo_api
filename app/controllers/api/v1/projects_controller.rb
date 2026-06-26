module Api
  module V1
    class ProjectsController < BaseController
      before_action :set_project, only: [:show, :update, :destroy]

      def index
        projects = policy_scope(Project)
        projects = projects.search(params[:q])          if params[:q].present?
        projects = projects.where(status: params[:status]) if params[:status].present?
        projects = projects.includes(:tasks).order(created_at: :desc)

        render json: {
          success: true,
          data: projects.map { |p| project_payload(p) }
        }
      end

      def show
        authorize @project
        render json: {
          success: true,
          data:    project_detail_payload(@project)
        }
      end

      def create
        @project = current_company.projects.build(
          project_params.merge(user: current_user)
        )

        if @project.client_id.blank?
          internal_client = current_company.clients.find_by(internal: true)
          if internal_client
            @project.client = internal_client
          else
            return render json: {
              success: false,
              errors:  ['client_id is required — no internal client found for your company']
            }, status: :unprocessable_content
          end
        end

        if @project.client_id.present?
          unless current_company.clients.exists?(id: @project.client_id)
            return render json: {
              success: false,
              errors:  ['Client not found in your organization']
            }, status: :unprocessable_content
          end
        end

        authorize @project

        if @project.save
          render json: {
            success: true,
            data:    project_payload(@project)
          }, status: :created
        else
          render json: {
            success: false,
            errors:  @project.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def update
        authorize @project

        if project_params[:client_id].present?
          unless current_company.clients.exists?(id: project_params[:client_id])
            return render json: {
              success: false,
              errors:  ['Client not found in your organization']
            }, status: :unprocessable_content
          end
        end

        if @project.update(project_params)
          render json: {
            success: true,
            data:    project_payload(@project)
          }
        else
          render json: {
            success: false,
            errors:  @project.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        authorize @project
        @project.destroy
        render json: { success: true, message: 'Project deleted' }
      end

      private

      def set_project
        @project = policy_scope(Project).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { success: false, error: 'Project not found' }, status: :not_found
      end

      def project_params
        params.require(:project).permit(
          :title, :description, :status,
          :color, :start_date, :end_date, :client_id
        )
      end

      def project_payload(project)
        loaded_tasks = project.tasks.loaded? ? project.tasks.to_a : project.tasks.load.to_a
        total        = loaded_tasks.size
        completed    = loaded_tasks.count { |t| t.status == 'completed' }

        task_counts = loaded_tasks.group_by(&:status)
                                  .transform_values(&:count)

        completion_percentage = total.zero? ? 0 : ((completed.to_f / total) * 100).round

        {
          id:                    project.id,
          title:                 project.title,
          description:           project.description,
          status:                project.status,
          color:                 project.color,
          start_date:            project.start_date,
          end_date:              project.end_date,
          client_id:             project.client_id,
          task_counts:           task_counts,
          completion_percentage: completion_percentage,
          created_at:            project.created_at
        }
      end

      def project_detail_payload(project)
        project.tasks.load unless project.tasks.loaded?

        project_payload(project).merge(
          tasks: project.tasks.sort_by(&:position).map { |t| task_payload(t) }
        )
      end

      def task_payload(task)
        {
          id:             task.id,
          title:          task.title,
          description:    task.description,
          status:         task.status,
          priority:       task.priority,
          priority_color: task.priority_color,
          position:       task.position,
          due_date:       task.due_date,
          project_id:     task.project_id,
          assignee:       task.assignee ? {
            id:        task.assignee.id,
            full_name: task.assignee.full_name
          } : nil
        }
      end
    end
  end
end