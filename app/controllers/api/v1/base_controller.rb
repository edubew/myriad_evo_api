class Api::V1::BaseController < ActionController::API
  include Devise::Controllers::Helpers

  before_action :authenticate_user_from_token!
  before_action :ensure_company

  private

  # Custom method to authenticate via JWT from body or headers
  def authenticate_user_from_token!
    auth_header = request.headers['Authorization']

    if auth_header.blank?
      render json: { error: 'Missing token' }, status: :unauthorized and return
    end

    token = auth_header.split(' ').last
    
    begin
      decoded = Warden::JWTAuth::TokenDecoder.new.call(token)
      @current_user = User.find(decoded['sub'])
    rescue => e
      Rails.logger.error "JWT ERROR: #{e.message}"
      render json: { success: false, error: 'Unauthorized' }, status: :unauthorized
    end
  end

  # def autheynticate_user_from_token!
  #   token = request.headers['Authorization']&.split(' ')&.last
  #   return render_unauthorized unless token

  #   begin
  #     payload = JWT.decode(token, Rails.application.secrets.secret_key_base)[0]
  #     @current_user = User.find(payload['user_id'])
  #   rescue JWT::DecodeError => e
  #     Rails.logger.error "JWT ERROR: #{e.message}"
  #     render_unauthorized
  #   end
  # end

  def current_user
    @current_user
  end

  def current_company
    return nil unless current_user
    current_user.company
  end

  def ensure_company
    unless current_company
      render json: {
        success: false,
        error: 'No company associated with this account'
      }, status: :forbidden
    end
  end

  def render_success(data:, status: :ok)
    render json: { success: true, data: data }, status: status
  end

  def render_error(message:, status: :unprocessable_entity)
    render json: {
      success: false,
      error: message
    }, status: status
  end
end