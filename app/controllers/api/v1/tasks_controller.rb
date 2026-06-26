module Api
  module V1
    class TasksController < BaseController
      before_action :set_project
      before_action :set_task, only: [:update, :destroy]

      def index
        @tasks = @project.tasks.includes(:assignee).order(:position)
        skip_authorization  # reading tasks under an authorized project is fine

        render json: {
          success: true,
          data:    @tasks.map { |t| task_payload(t) }
        }
      end

      def create
        @task = @project.tasks.build(
          task_params.except(:assignee_id).merge(user: current_user)
        )

        @task.position = @project.tasks.where(status: @task.status).count

        if task_params[:assignee_id].present?
          assignee = current_company.users.find_by(id: task_params[:assignee_id])

          unless assignee
            return render json: {
              success: false,
              errors:  ['Assignee not found in your organization']
            }, status: :unprocessable_content
          end

          @task.assignee = assignee
        end

        authorize @task

        if @task.save
          render json: {
            success: true,
            data:    task_payload(@task)
          }, status: :created
        else
          Rails.logger.error @task.errors.full_messages
          render json: {
            success: false,
            errors:  @task.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def update
        authorize @task

        if task_params[:assignee_id].present?
          assignee = current_company.users.find_by(id: task_params[:assignee_id])

          unless assignee
            return render json: {
              success: false,
              errors:  ['Assignee not found in your organization']
            }, status: :unprocessable_content
          end
        end

        if @task.update(task_params)
          render json: {
            success: true,
            data:    task_payload(@task)
          }
        else
          render json: {
            success: false,
            errors:  @task.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        authorize @task
        @task.destroy
        render json: { success: true, message: 'Task deleted' }
      end

      def reorder
        authorize Task, :reorder?

        tasks_order = params[:tasks]

        unless tasks_order.is_a?(Array)
          return render json: {
            success: false,
            error:   'Expected an array of tasks'
          }, status: :unprocessable_content
        end

        ActiveRecord::Base.transaction do
          tasks_order.each_with_index do |task_data, index|
            # Safe: @project is already scoped to current_company
            @project.tasks
              .find(task_data[:id])
              .update!(
                status:   task_data[:status],
                position: index
              )
          end
        end

        render json: { success: true }

      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error:   'One or more tasks not found or do not belong to this project'
        }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: {
          success: false,
          errors:  e.record.errors.full_messages
        }, status: :unprocessable_content
      end

      private

      def set_project
        @project = current_company.projects.find(params[:project_id])
      rescue ActiveRecord::RecordNotFound
        render json: { success: false, error: 'Project not found' }, status: :not_found
      end

      def set_task
        @task = @project.tasks.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { success: false, error: 'Task not found' }, status: :not_found
      end

      def task_params
        params.require(:task).permit(
          :title, :description, :status,
          :priority, :position, :due_date, :assignee_id
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
            full_name: task.assignee.full_name,
            avatar:    task.assignee.avatar,
            initials:  "#{task.assignee.first_name[0]}#{task.assignee.last_name[0]}"
          } : nil
        }
      end
    end
  end
end