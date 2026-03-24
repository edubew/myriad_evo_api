module Api
  module V1
    class TasksController < BaseController
      before_action :set_project

      def create
        @task = @project.tasks.build(task_params)
        @task.user = current_user
        @task.position = @project.tasks
          .where(status: @task.status).count

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

      # Handle drag and drop reordering
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
        @project = current_user.projects.find(params[:project_id])
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
          id:             task.id,
          title:          task.title,
          description:    task.description,
          status:         task.status,
          priority:       task.priority,
          priority_color: task.priority_color,
          position:       task.position,
          due_date:       task.due_date,
          project_id:     task.project_id,
          assignee: task.assignee ? {
            id:        task.assignee.id,
            full_name: task.assignee.full_name
          } : nil
        }
      end
    end
  end
end