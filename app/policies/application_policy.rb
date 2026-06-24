class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "must be logged in" unless user
    @user   = user
    @record = record
  end

  # Default: nobody can do anything unless explicitly permitted
  def index?   = false
  def show?    = false
  def create?  = false
  def update?  = false
  def destroy? = false

  # Shared helpers
  def admin?        = user.admin?
  def owner?        = user.owner?
  def viewer?       = user.viewer?
  def owns?(rec)    = rec.respond_to?(:user_id) && rec.user_id == user.id
  def same_company?(rec) = rec.company_id == user.company_id

  class Scope
    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    # Default scope: always restrict to current company
    def resolve
      @scope.where(company_id: @user.company_id)
    end
  end
end