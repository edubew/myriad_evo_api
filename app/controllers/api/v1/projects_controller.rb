module Api
  module V1
    class ProjectsController < BaseController
      before_action :set_project, only: [:show, :update, :destroy]

      def index
        @projects = current_user.projects
        
        @projects = @projects.search(params[:q]) if params[:q].present?
        @projects = @projects.where(status: params[:status]) if params[:status].present?
        @projects = @projects.order(created_at: :desc)

        render json: {
          success: true,
          data: @projects.map{ |p| project_payload(p)}
        }
      end

      def show
        render json: {
          success: true,
          data: project_detail_payload(@project)
        }
      end

      def create
        @project = current_user.projects.build(project_params)

        # ✅ Auto-assign client if missing
        if @project.client_id.nil?
          @project.client = current_user.clients.first
        end

        if @project.save
          render json: {
            success: true,
            data: project_payload(@project)
          }, status: :created
        else
          render json: {
            success: false,
            errors: @project.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def update
        if @project.update(project_params)
          render json: {
            success: true,
            data: project_payload(@project)
          }
        else
          render json: {
            success: false,
            errors: @project.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        @project.destroy
        render json: { success: true, message: 'Project deleted' }
      end

      private

      def set_project
        @project = current_user.projects.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: 'Project not found'
        }, status: :not_found
      end

      def project_params
        params.require(:project).permit(
          :title, :description, :status,
          :color, :start_date, :end_date, :client_id
        )
      end

      def project_payload(project)
        {
          id: project.id,
          title: project.title,
          description: project.description,
          status: project.status,
          color:  project.color,
          start_date: project.start_date,
          end_date:   project.end_date,
          client_id:  project.client_id,
          task_counts: project.task_counts,
          completion_percentage: project.completion_percentage,
          created_at: project.created_at
        }
      end

      def project_detail_payload(project)
        project_payload(project).merge(
          tasks: project.tasks.order(:position).map { |t| task_payload(t) }
        )
      end

      def task_payload(task)
        {
          id:           task.id,
          title: task.title,
          description: task.description,
          status: task.status,
          priority: task.priority,
          priority_color: task.priority_color,
          position: task.position,
          due_date: task.due_date,
          project_id: task.project_id,
          assignee: task.assignee ? {
            id: task.assignee.id,
            full_name: task.assignee.full_name
          } : nil
        }
      end
    end
  end
end