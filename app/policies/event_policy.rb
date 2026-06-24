class EventPolicy < ApplicationPolicy
  include CompanyScopedPolicy

  # Project-sourced events cannot be edited via this controller
  def update?  = can_write? && record.manual?
  def destroy? = can_write? && record.manual? && (admin? || owns?(record))

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(company_id: user.company_id)
    end
  end
end