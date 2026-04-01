class ApplicationController < ActionController::API
  include Devise::Controllers::Helpers

  before_action :set_default_response_format
  before_action :authenticate_user_from_token!

  private

  def set_default_response_format
    request.format = :json
  end
end