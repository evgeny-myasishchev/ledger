class HomeController < ApplicationController
  def index
    @ledgers = Projections::Ledger.get_user_ledgers current_user
    @accounts = Projections::Account.get_user_accounts current_user
    @tags = Projections::Tag.get_user_tags current_user
    @categories = Projections::Category.get_user_categories current_user
  end
end
