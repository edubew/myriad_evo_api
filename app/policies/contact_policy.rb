class ContactPolicy < ApplicationPolicy
  # A contact's company is read through its parent client
  def show?    = user.company_id == record.client.company_id
  def create?  = !user.viewer? && user.company_id == record.client.company_id
  def update?  = !user.viewer? && user.company_id == record.client.company_id
  def destroy? = !user.viewer? && user.company_id == record.client.company_id

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(company_id: user.company_id)
    end
  end
end
