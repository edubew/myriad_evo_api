module Api
  module V1
    class GoalsController < BaseController
      before_action :set_goal, only: [:show, :update, :destroy]  # FIX 2: added :show
 
      def index
        @goals = policy_scope(Goal)
        @goals = @goals.for_quarter(params[:quarter], params[:year]) if params[:quarter].present?
        @goals = @goals.order(created_at: :desc)
 
        render json: {
          success: true,
          data:    @goals.map { |g| goal_payload(g) }
        }
      end

      def show
        authorize @goal
        render json: { success: true, data: goal_payload(@goal) }
      end
 
      def create
        @goal = current_company.goals.build(goal_params.merge(user: current_user))
        authorize @goal
 
        if @goal.save
          render json: {
            success: true,
            data:    goal_payload(@goal)
          }, status: :created
        else
          render json: {
            success: false,
            errors:  @goal.errors.full_messages
          }, status: :unprocessable_content
        end
      end
 
      def update
        authorize @goal
 
        if @goal.update(goal_params)
          render json: { success: true, data: goal_payload(@goal) }
        else
          render json: {
            success: false,
            errors:  @goal.errors.full_messages
          }, status: :unprocessable_content
        end
      end
 
      def destroy
        authorize @goal
        @goal.destroy
        render json: { success: true, message: 'Goal deleted' }
      end
 
      private
 
      def set_goal
        @goal = policy_scope(Goal).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { success: false, error: 'Goal not found' }, status: :not_found
      end
 
      def goal_params
        params.require(:goal).permit(
          :title, :description, :target_date,
          :progress, :status, :quarter, :year
        )
      end
 
      def goal_payload(goal)
        {
          id:          goal.id,
          title:       goal.title,
          description: goal.description,
          target_date: goal.target_date,
          progress:    goal.progress,
          status:      goal.status,
          quarter:     goal.quarter,
          year:        goal.year,
          created_at:  goal.created_at
        }
      end
    end
  end
end
 