module Users
  class InviteUserService < ApplicationService
    def initialize(company:, invited_by:, params:)
      @company    = company
      @invited_by = invited_by
      @params     = params
    end

    def call
      role = @params[:role].presence_in(CompanyMembership::ROLES) || 'member'

      # Prevent invite from escalating privileges beyond inviter's role
      if role == 'owner'
        return failure(['Cannot invite another owner'])
      end
      if role == 'admin' && !@invited_by.owner?
        return failure(['Only the owner can invite admins'])
      end

      ActiveRecord::Base.transaction do
        user = @company.users.create!(
          first_name:            @params[:first_name],
          last_name:             @params[:last_name],
          email:                 @params[:email],
          password:              SecureRandom.hex(16),
          password_confirmation: SecureRandom.hex(16),
          role:                  role
        )
        CompanyMembership.create!(
          user: user, company: @company,
          role: role, invited_at: Time.current
        )
        # TODO: send invite email with password reset link
        success(user)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end
  end
end