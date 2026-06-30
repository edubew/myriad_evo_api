class JwtDenylistCleanupJob < ApplicationJob
  queue_as :maintenance

  def perform
    deleted = JwtDenylist.where('exp < ?', Time.current).delete_all
    Rails.logger.info "JwtDenylistCleanupJob: removed #{deleted} expired tokens"
  end
end