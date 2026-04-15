class ApplicationController < ActionController::Base
  include Clerk::Authenticatable

  helper_method :current_user

  stale_when_importmap_changes

  private

  def current_user
    clerk.user
  end

  def authenticate_user!
    redirect_to clerk.sign_in_url unless clerk.session
  end
end
