class DocumentPolicy < ApplicationPolicy
  include CompanyScopedPolicy

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(company_id: user.company_id)
    end
  end
end