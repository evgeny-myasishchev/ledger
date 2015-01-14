class PendingTransactionsController < ApplicationController
  include Application::Commands::PendingTransactionCommands
  
  def index
    @transactions = Projections::PendingTransaction.get_pending_transactions current_user
    respond_to do |format|
      format.json { render json: @transactions }
    end
  end
  
  def report
    cmd = ReportPendingTransaction.from_hash params
    cmd.user = current_user
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
    render nothing: true
  end
end
