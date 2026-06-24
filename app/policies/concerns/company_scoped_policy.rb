module CompanyScopedPolicy
  def index?   = same_company_member?
  def show?    = same_company_member? && same_company?(record)
  def create?  = can_write?
  def update?  = can_write? && (admin? || owns?(record))
  def destroy? = can_destroy?

  private

  def same_company_member?
    user.company_id == record_company_id
  end

  def record_company_id
    record.respond_to?(:company_id) ? record.company_id : nil
  end

  def can_write?
    !user.viewer? && same_company_member?
  end

  def can_destroy?
    return false if user.viewer?
    return false unless same_company_member?
    admin? || owns?(record)
  end
end