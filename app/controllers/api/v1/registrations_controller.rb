module Api
  module V1
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json

      before_action :configure_permitted_parameters

      def create
        super
      end

      protected

      def configure_permitted_parameters
        devise_parameter_sanitizer.permit(:sign_up, keys: [
          :first_name,
          :last_name,
          :email,
          :password,
          :password_confirmation
        ])
      end

      private

      def respond_with(resource, _opts = {})
        if resource.persisted?
          render json: {
            success: true,
            message: 'Account created successfully',
            user: user_payload(resource)
          }, status: :created
        else
          render json: {
            success: false,
            errors: resource.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def user_payload(user)
        {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          role: user.role,
          full_name: user.full_name
        }
      end
    end
  end
end