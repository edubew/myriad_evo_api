module Api
  module V1
    class DailyTodosController < BaseController
      before_action :set_todo, only: [:update, :destroy]
 
      def index
        skip_authorization
        todos = current_user.daily_todos.for_today.ordered
        render json: {
          success: true,
          data:    todos.map { |t| todo_payload(t) }
        }
      end
 
      def create
        todo = current_user.daily_todos.build(
          text:     params[:text],
          date:     Date.today,
          position: current_user.daily_todos.for_today.count,
          company:  current_company
        )
        authorize todo
 
        if todo.save
          render json: {
            success: true,
            data:    todo_payload(todo)
          }, status: :created
        else
          render json: {
            success: false,
            errors:  todo.errors.full_messages
          }, status: :unprocessable_content
        end
      end
 
      def update
        authorize @todo
        @todo.update(done: params[:done])
        render json: { success: true, data: todo_payload(@todo) }
      end
 
      def destroy
        authorize @todo
        @todo.destroy
        render json: { success: true }
      end
 
      private
 
      def set_todo
        @todo = current_user.daily_todos.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { success: false, error: 'Todo not found' }, status: :not_found
      end
 
      def todo_payload(todo)
        {
          id:       todo.id,
          text:     todo.text,
          done:     todo.done,
          date:     todo.date,
          position: todo.position,
          type:     'manual',
          source:   'manual'
        }
      end
    end
  end
end