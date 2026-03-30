module Api
  module V1
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json

      before_action :configure_permitted_parameters, only: [:create]

      def create
        user_params = params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
        @user = User.new(user_params)

        if @user.save
          render json: {
            success: true,
            message: 'Account created successfully',
            user: user_payload(@user)
          }, status: :created
        else
          render json: {
            success: false,
            errors: @user.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      private

      def configure_permitted_parameters
        devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
      end

      def user_payload(user)
        {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          role: user.role,
          full_name: user.full_name,
          avatar: user.avatar
        }
      end
    end
  end
end