class GoalPolicy < ApplicationPolicy
  include CompanyScopedPolicy

  # Goals are company-wide. anyone can update their own
  def update?  = can_write? && (admin? || owns?(record))
  def destroy? = can_write? && (admin? || owns?(record))

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(company_id: user.company_id)
    end
  end
end