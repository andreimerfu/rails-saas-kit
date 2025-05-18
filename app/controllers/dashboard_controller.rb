class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @organization = current_user.organization
  end
end
