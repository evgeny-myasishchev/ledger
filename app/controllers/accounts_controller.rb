class AccountsController < ApplicationController
  include Application::Commands::LedgerCommands
  include Application::Commands::AccountCommands
  
  def new
    @currencies = Currency.known
    @new_account_id = CommonDomain::Infrastructure::AggregateId.new_id
    respond_to do |format|
      format.json {
        render json: {currencies: @currencies, new_account_id: @new_account_id}
      }
    end
  end
  
  def create
    dispatch_command CreateNewAccount.new params[:ledger_id], params
    render nothing: true
  end
  
  def rename
    dispatch_command RenameAccount.from_hash params
    render nothing: true
  end
  
  def close
    dispatch_command CloseAccount.new params[:ledger_id], params
    render nothing: true
  end
end
