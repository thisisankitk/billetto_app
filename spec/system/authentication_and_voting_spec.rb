require "rails_helper"

RSpec.describe "Authentication and voting", type: :system do
  before do
    driven_by(:rack_test)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
  end

  it "shows Clerk sign-in and sign-up mount points" do
    visit "/sign-in"
    expect(page).to have_css("#clerk-sign-in")

    visit "/sign-up"
    expect(page).to have_css("#clerk-sign-up")
  end

  it "redirects unauthenticated users to sign-in when attempting to vote" do
    Event.create!(external_id: "sys-1", title: "System event", starts_at: 1.day.from_now)

    visit root_path
    click_button("👍 0", match: :first)

    expect(page).to have_current_path("/sign-in", ignore_query: true)
  end
end
