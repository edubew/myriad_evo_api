class UserPolicy < ApplicationPolicy
  def index?   = admin?
  def create?  = admin?
  def update?  = admin? || record.id == user.id
  def destroy? = admin? && record.id != user.id && !record.owner?

  # Nobody can destroy the company owner
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(company_id: user.company_id)
    end
  end
end