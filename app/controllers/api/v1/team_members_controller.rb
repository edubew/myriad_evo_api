module Api
  module V1
    class TeamMembersController < BaseController
      before_action :set_member, only: [:update, :destroy]

      def index
        @members = current_user.team_members.order(:first_name)
        render json: {
          success: true,
          data: @members.map { |m| member_payload(m) }
        }
      end

      def create
        @member = current_user.team_members.build(member_params)
        if @member.save
          render json: {
            success: true,
            data: member_payload(@member)
          }, status: :created
        else
          render json: {
            success: false,
            errors: @member.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def update
        if @member.update(member_params)
          render json: { success: true, data: member_payload(@member) }
        else
          render json: {
            success: false,
            errors: @member.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        @member.destroy
        render json: { success: true, message: 'Team member removed' }
      end

      private

      def set_member
        @member = current_user.team_members.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: 'Team member not found'
        }, status: :not_found
      end

      def member_params
        params.require(:team_member).permit(
          :first_name, :last_name, :email,
          :phone, :role, :department, :bio, :avatar_url
        )
      end

      def member_payload(member)
        {
          id: member.id,
          full_name: member.full_name,
          first_name: member.first_name,
          last_name: member.last_name,
          initials:  member.initials,
          email: member.email,
          phone: member.phone,
          role: member.role,
          department: member.department,
          bio: member.bio,
          avatar: member.avatar
        }
      end
    end
  end
end