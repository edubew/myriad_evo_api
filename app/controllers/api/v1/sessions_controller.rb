module Api
  module V1
    class SessionsController < Devise::SessionsController
      respond_to :json

      private

      def respond_with(resource, _opts = {})
        render json: {
          success: true,
          message: 'Logged in successfully',
          user: user_payload(resource)
        }, status: :ok
      end

      def respond_to_on_destroy
        render json: {
          success: true,
          message: 'Logged out successfully'
        }, status: :ok
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