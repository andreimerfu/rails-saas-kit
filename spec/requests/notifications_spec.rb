require 'rails_helper'

RSpec.describe "Notifications", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :member, organization: organization) }

  before do
    sign_in user
  end

  describe "GET /notifications" do
    it "returns http success" do
      get "/notifications"
      expect(response).to have_http_status(:success)
    end
  end
end
