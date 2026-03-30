class Api::V1::BaseController < ActionController::API
  include Devise::Controllers::Helpers

  before_action :authenticate_user_from_token!

  private

  # Custom method to authenticate via JWT from body or headers
  def authenticate_user_from_token!
    auth_header = request.headers['Authorization']
    token = auth_header&.split(' ')&.last
    token ||= params[:token]

    if token
      begin
        payload = Warden::JWTAuth::TokenDecoder.new.call(token)
        @current_user = User.find(payload['sub'])
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    else
      render json: { error: 'Missing token' }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end
end