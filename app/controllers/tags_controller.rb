class TagsController < ApplicationController
  include Application::Commands::LedgerCommands
  
  def create
    dispatch_command CreateTag.new params[:ledger_id], params
    render nothing: true
  end
  
  def update
    dispatch_command RenameTag.new params[:ledger_id], params
    render nothing: true
  end
  
  def destroy
    dispatch_command RemoveTag.new params[:ledger_id], params
    render nothing: true
  end
end
