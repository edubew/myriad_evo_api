class InvoicePolicy < ApplicationPolicy
  include CompanyScopedPolicy

  # Only admins can mark invoices as paid or change financial status
  def mark_paid?  = admin?
  def update?     = can_write? && (admin? || owns?(record))

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(company_id: user.company_id)
    end
  end
end