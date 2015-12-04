class Application::PendingTransactionsService < CommonDomain::CommandHandler
  include Domain
  include Application::Commands
  
  on PendingTransactionCommands::ReportPendingTransaction do |cmd|
    begin_unit_of_work cmd.headers do |uow|
      transaction = PendingTransaction.new
      transaction.report cmd.user, cmd.id, cmd.amount, 
        date: cmd.date, tag_ids: cmd.tag_ids, comment: cmd.comment, type_id: cmd.type_id, account_id: cmd.account_id
      uow.add_new transaction
    end
  end
  
  handle(PendingTransactionCommands::AdjustPendingTransaction).with(Domain::PendingTransaction).using(:adjust)
  
  on PendingTransactionCommands::ApprovePendingTransaction do |cmd|
    begin_unit_of_work cmd.headers do |uow|
      transaction = uow.get_by_id Domain::PendingTransaction, cmd.id
      account = uow.get_by_id Domain::Account, transaction.account_id
      transaction.approve account
    end
  end
  
  on PendingTransactionCommands::AdjustAndApprovePendingTransaction do |cmd|
    begin_unit_of_work cmd.headers do |uow|
      transaction = uow.get_by_id Domain::PendingTransaction, cmd.id
      adjust_pending_transaction transaction, cmd
      account = uow.get_by_id Domain::Account, transaction.account_id
      transaction.approve account
    end
  end
  
  on PendingTransactionCommands::AdjustAndApprovePendingTransferTransaction do |cmd|
    begin_unit_of_work cmd.headers do |uow|
      transaction = uow.get_by_id Domain::PendingTransaction, cmd.id
      adjust_pending_transaction transaction, cmd
      account = uow.get_by_id Domain::Account, transaction.account_id
      receiving_account = uow.get_by_id Domain::Account, cmd.receiving_account_id
      transaction.approve_transfer account, receiving_account, cmd.amount_received
    end
  end
  
  handle(PendingTransactionCommands::RejectPendingTransaction).with(Domain::PendingTransaction).using(:reject)
  
  private

  def adjust_pending_transaction(transaction, cmd)
    transaction.adjust amount: cmd.amount, date: cmd.date, tag_ids: cmd.tag_ids, comment: cmd.comment, account_id: cmd.account_id, type_id: cmd.type_id
  end
end