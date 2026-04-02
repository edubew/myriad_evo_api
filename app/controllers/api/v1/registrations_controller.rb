module Api
  module V1
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json

      before_action :configure_permitted_parameters, only: [:create]

      def create
        # user_params = params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
        # @user = User.new(user_params)
         build_resource(sign_up_params)

        # if @user.save
        #   render json: {
        #     success: true,
        #     message: 'Account created successfully',
        #     user: user_payload(@user)
        #   }, status: :created
        # else
        #   render json: {
        #     success: false,
        #     errors: @user.errors.full_messages
        #   }, status: :unprocessable_content
        # end

        if resource.company_id.blank?
          company_name = params.dig(:user, :company_name) ||
                         "#{resource.first_name}'s Company"
          company = Company.first || Company.create!(
            name: company_name,
            slug: generate_company_slug(company_name)
          )
          resource.company = company
        end

        resource.save
        yield resource if block_given?
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

      protected

      def configure_permitted_parameters
        devise_parameter_sanitizer.permit(:sign_up, keys: [
          :first_name, :last_name, :email,
          :password, :password_confirmation,
          :company_name, :company_id
        ])
      end

      private

      # def configure_permitted_parameters
      #   devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
      # end

      def generate_company_slug(name)
        base = name.to_s.downcase.gsub(/[^a-z0-9]+/, '-').strip
        slug = base
        count = 0
        while Company.exists?(slug: slug)
          count += 1
          slug = "#{base}-#{count}"
        end
        slug
      end

      def user_payload(user)
        {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          role: user.role,
          full_name: user.full_name,
          avatar: user.avatar,
          company_id:   user.company_id,
          company_name: user.company&.name
        }
      end
    end
  end
end