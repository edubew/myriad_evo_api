module Api
  module V1
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json

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
          }, status: :unprocessable_entity
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