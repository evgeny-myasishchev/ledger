class TransactionsController < ApplicationController
  include Application::Commands::AccountCommands
  
  def index
    @transactions = Projections::Transaction.get_account_transactions current_user, params[:account_id]
    respond_to do |format|
      format.json { render json: @transactions }
    end
  end
  
  def report_income
    dispatch_command ReportIncome.build_from_params params
    render nothing: true
  end
  
  def report_expence
    dispatch_command ReportExpence.build_from_params params
    render nothing: true
  end
end
