class DealPolicy < ApplicationPolicy
  include CompanyScopedPolicy

  def reorder?  = can_write?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(company_id: user.company_id)
    end
  end
end