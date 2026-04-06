class ApplicationController < ActionController::Base
  include Clerk::Authenticatable

  helper_method :current_user

  stale_when_importmap_changes

  private

  def current_user
    clerk.user
  end

  def authenticate_user!
    redirect_to "/sign-in" unless current_user.present?
  end
end