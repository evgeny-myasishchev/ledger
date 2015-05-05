class TransactionsController < ApplicationController
  include Application::Commands::AccountCommands
  
  def index
    @transactions = Projections::Transaction.get_root_data current_user, params[:account_id]
    respond_to do |format|
      format.json { render json: @transactions }
    end
  end
  
  def search
    from = params[:from].to_i
    to = params[:to].to_i
    # TODO: Make sure criteri.from/to dates are converted from iso 8601 string to DateTime object
    result = Projections::Transaction.search current_user, params[:account_id], criteria: params[:criteria], offset: from, limit: to - from, with_total: params['with-total']
    respond_to do |format|
      format.json { 
        render json: result
      }
    end
  end
  
  def report_income
    dispatch_transaction_command ReportIncome
  end
  
  def report_expense
    dispatch_transaction_command ReportExpense
  end
  
  def report_refund
    dispatch_transaction_command ReportRefund
  end
  
  def report_transfer
    dispatch_transaction_command ReportTransfer
  end
  
  def adjust_amount
    dispatch_command AdjustAmount.new params
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
  
  def convert_type
    params[:type_id] = params[:type_id].to_i
    dispatch_command ConvertTransactionType.new params
    render nothing: true
  end
  
  def destroy
    dispatch_command RemoveTransaction.new params
    render nothing: true
  end
    
  def move_to
    dispatch_command MoveTransaction.new params
    render nothing: true
  end
  
  private def dispatch_transaction_command command_class
    dispatch_command command_class.from_hash params
    render nothing: true
  end
end
