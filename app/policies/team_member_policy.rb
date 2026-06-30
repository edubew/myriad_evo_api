class TeamMemberPolicy < ApplicationPolicy
  include CompanyScopedPolicy

  # Any non-viewer company member can create a directory entry
  def create? = !user.viewer? && user.company_id == record.company_id

  # Only admins or the person who created the entry can edit/delete it
  def update?  = can_write? && (admin? || owns?(record))
  def destroy? = can_write? && (admin? || owns?(record))

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(company_id: user.company_id)
    end
  end
end