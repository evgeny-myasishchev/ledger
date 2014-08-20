class CategoriesController < ApplicationController
  include Application::Commands::LedgerCommands
  
  def create
    category_id = dispatch_command CreateCategory.new params[:ledger_id], params
    render json: {category_id: category_id}
  end
  
  def update
    dispatch_command RenameCategory.new params[:ledger_id], params
    render nothing: true
  end
  
  def destroy
    dispatch_command RemoveCategory.new params[:ledger_id], params
    render nothing: true
  end
end
