class HomeController < ApplicationController
  def index
    @ledgers = Projections::Ledger.get_user_ledgers current_user
    @accounts = Projections::Account.get_user_accounts current_user
    @tags = Projections::Tag.get_user_tags current_user
    @categories = Projections::Category.get_user_categories current_user
    @pending_transactions_count = Projections::PendingTransaction.get_pending_transactions_count current_user
  end
end
