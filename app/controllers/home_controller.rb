class HomeController < ApplicationController
  def index
    @accounts = Projections::Account.get_user_accounts current_user
    @tags = Projections::Tag.get_user_tags current_user
  end
end
