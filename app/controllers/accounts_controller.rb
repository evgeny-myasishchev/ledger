class AccountsController < ApplicationController
  include Application::Commands::LedgerCommands
  include Application::Commands::AccountCommands
  
  def create
    dispatch_command CreateNewAccount.new params[:ledger_id], params
    render nothing: true
  end
  
  def close
    dispatch_command CloseAccount.new params[:ledger_id], params
    render nothing: true
  end
  
  def rename
    dispatch_command RenameAccount.from_hash params
    render nothing: true
  end
end
