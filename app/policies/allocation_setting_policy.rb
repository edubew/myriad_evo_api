class AllocationSettingPolicy < ApplicationPolicy
  def show?   = user.company_id == record.company_id
  def update? = admin? && user.company_id == record.company_id
end