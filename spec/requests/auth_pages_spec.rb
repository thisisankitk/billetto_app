require "rails_helper"

RSpec.describe "Authentication pages", type: :request do
  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
  end

  describe "GET /sign-in" do
    it "renders the Clerk sign-in mount point" do
      get "/sign-in"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("clerk-sign-in")
    end
  end

  describe "GET /sign-up" do
    it "renders the Clerk sign-up mount point" do
      get "/sign-up"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("clerk-sign-up")
    end
  end
end
