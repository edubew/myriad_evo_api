class Api::V1::BaseController < ActionController::API
  include Devise::Controllers::Helpers
  include Pundit::Authorization

  before_action :authenticate_user_from_token!
  before_action :ensure_company!
  after_action  :verify_authorized,      except: :index
  after_action  :verify_policy_scoped,   only:   :index

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def authenticate_user_from_token!
    auth_header = request.headers['Authorization']
    return render_unauthorized('Missing token') if auth_header.blank?

    token = auth_header.split(' ').last
    decoded = Warden::JWTAuth::TokenDecoder.new.call(token)
    jti     = decoded['jti']

    # Check denylist manually (belt-and-suspenders)
    if JwtDenylist.exists?(jti: jti)
      return render_unauthorized('Token has been revoked')
    end

    @current_user = User.includes(:company).find_by(id: decoded['sub'])
    render_unauthorized('Invalid token') unless @current_user

  rescue => e
    Rails.logger.error "JWT auth error: #{e.message}"
    render_unauthorized('Unauthorized')
  end

  def ensure_company!
    unless current_user&.company
      render json: { success: false, error: 'No company associated with this account' },
             status: :forbidden
    end
  end

  def current_user    = @current_user
  def current_company = @current_company ||= current_user&.company

  # Pundit user context
  def pundit_user = current_user

  def render_forbidden(e)
    render json: { success: false, error: 'You are not authorized to perform this action',
                   reason: e.message }, status: :forbidden
  end

  def render_unauthorized(msg = 'Unauthorized')
    render json: { success: false, error: msg }, status: :unauthorized
  end

  def render_not_found(e)
    render json: { success: false, error: 'Record not found' }, status: :not_found
  end

  def render_success(data:, status: :ok, **meta)
    render json: { success: true, data: data, **meta }, status: status
  end

  def render_error(message:, status: :unprocessable_entity, errors: [])
    render json: { success: false, error: message, errors: errors }, status: status
  end
end