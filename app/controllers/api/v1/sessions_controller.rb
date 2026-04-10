class Api::V1::SessionsController < Api::V1::BaseController
  respond_to :json
  skip_before_action :authenticate_user_from_token!, only: [:create], raise: false
  skip_before_action :ensure_company, only: [:create], raise: false

  def create
    user = User.find_by(email: params.dig(:user, :email))

    if user&.valid_password?(params.dig(:user, :password))
      token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
      
      render json: {
      success: true,
      message: "Logged in successfully",
      token: token,
      user: user_payload(user)
    }
    else
      render json: {
        success: false,
        errors: ["Invalid email or password"]
      }, status: :unauthorized
    end
  end

  def destroy
    render json: { success: true, message: "Logged out successfully" }, status: :ok
  end

  def demo_login
    user = User.find_by(email: "demo@coredesk.com")

    unless user
      return render json: {
        success: false,
        error: "Demo account not configured"
      }, status: :not_found
    end

    token, _payload = Warden::UserEncoder.new.call(user, :user, nil)
    DemoWorkspaceResetJob.set(wait: 2.minutes).perform_later(user.id)

    render json: {
      success: true,
      message: "Demo login successful",
      token: token,
      user: user_payload(user)
    }
  end

 private

  def user_payload(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      role:  user.role,
      full_name: user.full_name,
      avatar: user.avatar,
      company_id: user.company_id,
      company_name: user.company&.name
    }
  end
end