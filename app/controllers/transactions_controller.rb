class TransactionsController < ApplicationController
  include Application::Commands::AccountCommands
  
  def index
    @transactions = Projections::Transaction.get_account_transactions current_user, params[:account_id]
    respond_to do |format|
      format.json { render json: @transactions }
    end
  end
  
  def report_income
    dispatch_transaction_command ReportIncome
  end
  
  def report_expence
    dispatch_transaction_command ReportExpence
  end
  
  def report_refund
    dispatch_transaction_command ReportRefund
  end
  
  def report_transfer
    dispatch_transaction_command ReportTransfer
  end
  
  private def dispatch_transaction_command command_class
    dispatch_command command_class.build_from_params params
    render nothing: true
  end
end
