class Api::V1::SessionsController < Api::V1::BaseController
  respond_to :json

  skip_before_action :authenticate_user_from_token!, only: [:create, :demo_login], raise: false
  skip_before_action :ensure_company!,               only: [:create, :demo_login], raise: false

  # Pundit: login/logout are exempt from resource-level authorization
  after_action :skip_authorization

  def create
    user = User.find_by(email: params.dig(:user, :email)&.downcase&.strip)

    if user&.valid_password?(params.dig(:user, :password))
      token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)

      render json: {
        success: true,
        message: 'Logged in successfully',
        token:   token,
        user:    user_payload(user)
      }
    else
      render json: {
        success: false,
        errors:  ['Invalid email or password']
      }, status: :unauthorized
    end
  end

  def destroy
    token = request.headers['Authorization']&.split(' ')&.last

    if token.present?
      begin
        decoded = Warden::JWTAuth::TokenDecoder.new.call(token)
        JwtDenylist.create!(
          jti: decoded['jti'],
          exp: Time.at(decoded['exp'])
        )
      rescue => e
        # Token is already invalid/expired — nothing to revoke
        Rails.logger.info "Logout: token not revoked (#{e.class}: #{e.message})"
      end
    end

    render json: { success: true, message: 'Logged out successfully' }
  end

    def demo_login
    user = User.find_by(email: 'demo@coredesk.com')

    unless user
      return render json: {
        success: false,
        error:   'Demo account not configured'
      }, status: :not_found
    end

    # Revoke any active demo token that may still be alive
    # so the reset job from a prior session does not delete data mid-new-session
    revoke_existing_demo_tokens(user)

    token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)

    DemoWorkspaceResetJob.set(wait: 30.minutes).perform_later(user.id)

    render json: {
      success: true,
      message: 'Demo login successful',
      token:   token,
      user:    user_payload(user)
    }
  end

  private

  def revoke_existing_demo_tokens(user)
    # The JTI matcher strategy stores the current_sign_in_at; rotating jti
    # via update_column invalidates all previously issued tokens for this user
    user.update_column(:jti, SecureRandom.uuid) if user.respond_to?(:jti)
  rescue => e
    Rails.logger.warn "Demo token revocation failed: #{e.message}"
  end

  def user_payload(user)
    {
      id:           user.id,
      email:        user.email,
      first_name:   user.first_name,
      last_name:    user.last_name,
      role:         user.role,
      full_name:    user.full_name,
      avatar:       user.avatar,
      company_id:   user.company_id,
      company_name: user.company&.name
    }
  end
end