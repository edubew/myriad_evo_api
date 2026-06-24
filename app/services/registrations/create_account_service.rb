module Registrations
  class CreateAccountService < ApplicationService
    def initialize(user_params:, company_name: nil)
      @user_params  = user_params
      @company_name = company_name || derive_company_name(user_params)
    end

    def call
      ActiveRecord::Base.transaction do
        company = create_company!
        user    = create_user!(company)
        create_membership!(user, company, role: 'owner')
        create_allocation_setting!(company, user)
        success({ user: user, company: company })
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    def create_company!
      Company.create!(
        name: @company_name,
        plan: 'starter'
      )
    end

    def create_user!(company)
      company.users.create!(@user_params.merge(role: 'owner'))
    end

    def create_membership!(user, company, role:)
      CompanyMembership.create!(
        user: user, company: company, role: role,
        accepted_at: Time.current
      )
    end

    def create_allocation_setting!(company, user)
      AllocationSetting.create!(
        company: company, user: user,
        salary_pct: 40.0, ops_pct: 25.0, profit_pct: 35.0
      )
    end

    def derive_company_name(params)
      "#{params[:first_name]&.strip}'s Company"
    end
  end
end