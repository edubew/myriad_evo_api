module Api
  module V1
    class TasksController < BaseController
      before_action :set_project

      def index
        @tasks = @project.tasks
        .includes(:assignee)
        .order(:position)
        render json: {
          success: true,
          data: @tasks.map { |t| task_payload(t) }
        }
      end

      def create
        @task = @project.tasks.build(
          task_params.except(:assignee_id).merge(
          user: current_user,
          company: current_company
        ))
        # @task.user = current_user
        @task.position = @project.tasks
          .where(status: @task.status).count

        if task_params[:assignee_id].present?
          # assignee = User.find_by(id: task_params[:assignee_id])
          @task.assignee = User.find_by(id: task_params[:assignee_id])

          rescue => e
            Rails.logger.error "TASK CREATE ERROR: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")

            render_error(message: 'Internal server error', status: :internal_server_error)
          end
        end

        if @task.save
          render json: {
            success: true,
            data: task_payload(@task)
          }, status: :created
        else
          render json: {
            success: false,
            errors: @task.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def update
        @task = @project.tasks.find(params[:id])
        if @task.update(task_params)
          render json: {
            success: true,
            data: task_payload(@task)
          }
        else
          render json: {
            success: false,
            errors: @task.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        @task = @project.tasks.find(params[:id])
        @task.destroy
        render json: { success: true, message: 'Task deleted' }
      end

      def reorder
        tasks_order = params[:tasks]
        tasks_order.each_with_index do |task_data, index|
          @project.tasks
            .find(task_data[:id])
            .update(
              status:   task_data[:status],
              position: index
            )
        end
        render json: { success: true }
      end

      private

      def set_project
        @project = current_company.projects.find(params[:project_id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: 'Project not found'
        }, status: :not_found
      end

      def task_params
        params.require(:task).permit(
          :title, :description, :status,
          :priority, :position, :due_date, :assignee_id
        )
      end

      def task_payload(task)
        {
          id: task.id,
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
            full_name: task.assignee.full_name,
            avatar: task.assignee.avatar,
            initials: "#{task.assignee.first_name[0]}#{task.assignee.last_name[0]}"
          } : nil
        }
      end
    end
  end
end