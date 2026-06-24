class DailyTodoPolicy < ApplicationPolicy
  # Todos are strictly personal — only the owner ever sees theirs
  def index?   = record == user  # policy for collection
  def show?    = record.user_id == user.id
  def create?  = !user.viewer?
  def update?  = record.user_id == user.id
  def destroy? = record.user_id == user.id

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user_id: user.id)
    end
  end
end