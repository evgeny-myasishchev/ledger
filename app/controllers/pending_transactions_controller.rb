class PendingTransactionsController < ApplicationController
  include Application::Commands::PendingTransactionCommands
  
  def index
    @transactions = Projections::PendingTransaction.get_pending_transactions current_user
    respond_to do |format|
      format.json { render json: @transactions }
    end
  end
  
  def report
    params[:user] = current_user
    cmd = ReportPendingTransaction.from_hash params
    cmd.headers[:bank_name] = params[:bank_name] if params[:bank_name]
    cmd.headers[:bank_bic_code] = params[:bank_bic_code] if params[:bank_bic_code]
    dispatch_command cmd
    render nothing: true
  end
  
  def adjust
    dispatch_command AdjustPendingTransaction.from_hash params
    render nothing: true
  end
  
  def approve
    dispatch_command ApprovePendingTransaction.from_hash params
    render nothing: true
  end
  
  def adjust_and_approve
    dispatch_command AdjustAndApprovePendingTransaction.from_hash params
    render nothing: true
  end
  
  def destroy
    dispatch_command RejectPendingTransaction.new params
    render nothing: true
  end
end
