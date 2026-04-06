module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  def current_user_id
    @current_user_id
  end

  private

  def authenticate_user!
    clerk_user = request.env["clerk.user"]

    if clerk_user.present?
      @current_user_id = clerk_user["id"]
    else
      redirect_to "/sign-in"
    end
  end
end