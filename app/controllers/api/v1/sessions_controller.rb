class Api::V1::SessionsController < Devise::SessionsController
  respond_to :json
  skip_before_action :authenticate_user_from_token!, only: [:create]
  skip_before_action :ensure_company, only: [:create]

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