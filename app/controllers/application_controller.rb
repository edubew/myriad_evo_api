class ApplicationController < ActionController::API
  before_action :set_default_response_format

  def current_user
    User.first
  end
  private

  def set_default_response_format
    request.format = :json
  end
end