class PendingTransactionsController < ApplicationController
  include Application::Commands::PendingTransactionCommands
  
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
end
