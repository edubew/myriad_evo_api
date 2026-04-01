class Api::V1::SessionsController < Devise::SessionsController
  respond_to :json

  def create
    # login_params = params.require(:user).permit(:email, :password)
    login_params = params[:user] || params.dig(:session, :user)
    email = login_params[:email]
    password = login_params[:password]
    user = User.find_by(email: email)

    # user = User.find_by(email: login_params[:email])

      if user&.valid_password?(password)
        token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
        
        render json: {
        success: true,
        message: "Logged in successfully",
        token: token,
        user: {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          role: user.role,
          full_name: user.full_name,
          avatar: user.avatar
        }
      }, status: :ok
      
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
end