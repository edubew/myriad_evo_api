class TaskPolicy < ApplicationPolicy
  include CompanyScopedPolicy

  # Members can update tasks assigned to them, even if they didn't create them
  def update?
    return false if user.viewer?
    same_company_member? && (admin? || owns?(record) || assigned_to_me?)
  end

  def reorder? = can_write?

  private

  def assigned_to_me?
    record.assignee_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(company_id: user.company_id)
    end
  end
end