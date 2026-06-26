module Api
  module V1
    class UsersController < BaseController
      before_action :set_user, only: [:update, :destroy]

      def index
        authorize User
        users = policy_scope(User).order(:first_name)
        render json: {
          success: true,
          data:    users.map { |u| user_payload(u) }
        }
      end

      def create
        authorize User

        # Only admins can create users; only owners can create admins
        role = permitted_role(params.dig(:user, :role))

        user = current_company.users.build(
          first_name:            params.dig(:user, :first_name),
          last_name:             params.dig(:user, :last_name),
          email:                 params.dig(:user, :email)&.downcase&.strip,
          password:              params.dig(:user, :password) || SecureRandom.hex(16),
          password_confirmation: params.dig(:user, :password) || SecureRandom.hex(16),
          role:                  role
        )

        if user.save
          CompanyMembership.create!(
            user:        user,
            company:     current_company,
            role:        role,
            invited_at:  Time.current,
            accepted_at: Time.current
          )

          render json: {
            success: true,
            data:    user_payload(user)
          }, status: :created
        else
          render json: {
            success: false,
            errors:  user.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      # PATCH /api/v1/users/:id — admins update anyone; members update only themselves
      def update
        authorize @user

        if @user.update(update_params)
          # Keep CompanyMembership role in sync when an admin changes a user's role
          if update_params[:role].present?
            @user.company_membership&.update(role: update_params[:role])
          end

          render json: { success: true, data: user_payload(@user) }
        else
          render json: {
            success: false,
            errors:  @user.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      # DELETE /api/v1/users/:id — admins only; cannot delete self or owner
      def destroy
        authorize @user

        if @user == current_user
          return render json: {
            success: false,
            error:   'You cannot delete your own account'
          }, status: :forbidden
        end

        if @user.owner?
          return render json: {
            success: false,
            error:   'The company owner account cannot be deleted'
          }, status: :forbidden
        end

        @user.destroy
        render json: { success: true }
      end

      private

      def set_user
        @user = policy_scope(User).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { success: false, error: 'User not found' }, status: :not_found
      end

      
      def update_params
        allowed = [:first_name, :last_name, :avatar_url]
        # Only admins can change someone's role; members updating themselves
        # cannot self-promote
        allowed << :role if current_user.admin?
        params.require(:user).permit(*allowed)
      end

      # Constrain what role an admin is allowed to assign.
      # Only owners can make other admins; nobody can create another owner.
      def permitted_role(requested_role)
        requested_role = requested_role.to_s.presence_in(User::ROLES) || 'member'

        if requested_role == 'owner'
          'member'
        elsif requested_role == 'admin' && !current_user.owner?
          'member'
        else
          requested_role
        end
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