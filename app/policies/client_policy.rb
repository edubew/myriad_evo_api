class ClientPolicy < ApplicationPolicy
  include CompanyScopedPolicy

  # Members can only delete clients they created; admins can delete any
  def destroy?
    can_write? && (admin? || owns?(record))
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(company_id: user.company_id)
    end
  end
end