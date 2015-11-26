class AccountsController < ApplicationController
  include Application::Commands::LedgerCommands
  include Application::Commands::AccountCommands
  
  def index
    @accounts = Projections::Account.get_user_accounts current_user
    respond_to do |format|
      format.json { render json: @accounts }
    end
  end
  
  def new
    @currencies = Currency.known
    @new_account_id = CommonDomain::Aggregate.new_id
    respond_to do |format|
      format.json {
        render json: {currencies: @currencies, new_account_id: @new_account_id}
      }
    end
  end
  
  def create
    dispatch_command CreateNewAccount.new params
    render nothing: true
  end
  
  def rename
    dispatch_command RenameAccount.new params
    render nothing: true
  end
  
  def close
    dispatch_command CloseAccount.new params
    render nothing: true
  end
  
  def reopen
    dispatch_command ReopenAccount.new params
    render nothing: true
  end
  
  def set_category
    dispatch_command SetAccountCategory.new params
    render nothing: true
  end
  
  def destroy
    dispatch_command RemoveAccount.new params
    render nothing: true
  end
end
