class CategoriesController < ApplicationController
  include Application::Commands::LedgerCommands
  
  def create
    category_id = dispatch_command CreateCategory.new params
    render json: {category_id: category_id}
  end
  
  def update
    dispatch_command RenameCategory.new params
    render nothing: true
  end
  
  def destroy
    dispatch_command RemoveCategory.new params
    render nothing: true
  end
end
