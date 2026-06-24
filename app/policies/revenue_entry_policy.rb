class RevenueEntryPolicy < ApplicationPolicy
  include CompanyScopedPolicy

  # Only admins see all revenue; members see their own
  class Scope < ApplicationPolicy::Scope
    def resolve
      base = scope.where(company_id: user.company_id)
      user.admin? ? base : base.where(user_id: user.id)
    end
  end
end