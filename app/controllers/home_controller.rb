class HomeController < ApplicationController
  def index
    @accounts = Projections::Account.get_user_accounts current_user
  end
end
