class DemoWorkspaceResetJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    company = user.company
    return unless company

    # Reset projects
    company.projects.update_all(
      status: "active",
      completion_percentage: 0
    )

    # Reset tasks
    company.tasks.update_all(
      status: "backlog",
      completed_at: nil
    )

    # Reset deals (optional demo realism)
    company.deals.update_all(
      status: "open"
    )

    Rails.logger.info "Demo workspace reset for company #{company.id}"
  end
end