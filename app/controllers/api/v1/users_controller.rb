module Api
  module V1
    class UsersController < BaseController
      before_action :require_admin!

      def index
        users = current_company.users.order(:first_name)
        render json: {
          success: true,
          data: users.map { |u| user_payload(u) }
        }
      end

      def create
        data = params.require(:user).permit(:first_name, :last_name, :email, :password, :role)
        user = current_company.users.build(
          first_name: data[:first_name],
          last_name: data[:last_name],
          email: data[:email],
          password: data[:password],
          password_confirmation: data[:password],
          role: data[:role] || 'member',
          jti: SecureRandom.uuid
        )

        if user.save
          render json: {
            success: true,
            data: user_payload(user)
          }, status: :created
        else
          render json: {
            success: false,
            errors: user.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def update
        user = current_company.users.find(params[:id])
        if user.update(update_params)
          render json: { success: true, data: user_payload(user) }
        else
          render json: {
            success: false,
            errors: user.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        user = current_company.users.find(params[:id])
        if user == current_user
          render json: {
            success: false,
            error: "You cannot delete your own account"
          }, status: :forbidden
        else
          user.destroy
          render json: { success: true }
        end
      end

      private

      def require_admin!
        unless current_user.admin?
          render json: {
            success: false,
            error: 'Admin access required'
          }, status: :forbidden
        end
      end

      def update_params
        params.permit(:first_name, :last_name, :role, :avatar_url)
      end

      def user_payload(user)
        {
          id:         user.id,
          full_name:  user.full_name,
          first_name: user.first_name,
          last_name:  user.last_name,
          email:      user.email,
          role:       user.role,
          avatar:     user.avatar,
          created_at: user.created_at
        }
      end
    end
  end
end