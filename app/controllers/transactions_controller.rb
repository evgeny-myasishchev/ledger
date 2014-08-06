class TransactionsController < ApplicationController
  include Application::Commands::AccountCommands
  
  def index
    @transactions = Projections::Transaction.get_account_home_data current_user, params[:account_id]
    respond_to do |format|
      format.json { render json: @transactions }
    end
  end
  
  def range
    from = params[:from].to_i
    to = params[:to].to_i
    @transactions = Projections::Transaction.get_range current_user, params[:account_id], offset: from, limit: to - from
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
  
  def adjust_ammount
    dispatch_command AdjustAmmount.new params
    render nothing: true
  end
  
  def adjust_tags
    dispatch_command AdjustTags.new params
    render nothing: true
  end
  
  def adjust_date
    dispatch_command AdjustDate.new params
    render nothing: true
  end
  
  def adjust_comment
    dispatch_command AdjustComment.new params
    render nothing: true
  end
  
  def destroy
    dispatch_command RemoveTransaction.new params
    render nothing: true
  end
  
  private def dispatch_transaction_command command_class
    dispatch_command command_class.build_from_params params
    render nothing: true
  end
end
