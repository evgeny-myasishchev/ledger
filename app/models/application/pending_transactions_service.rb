class Application::PendingTransactionsService < CommonDomain::CommandHandler
  include Domain
  include Application::Commands
  include CommonDomain::NonAtomicUnitOfWork
  
  on PendingTransactionCommands::ReportPendingTransaction do |cmd|
    begin_unit_of_work cmd.headers do |uow|
      transaction = PendingTransaction.new
      transaction.report cmd.user, cmd.aggregate_id, cmd.amount, 
        date: cmd.date, tag_ids: cmd.tag_ids, comment: cmd.comment, type_id: cmd.type_id, account_id: cmd.account_id
      uow.add_new transaction
    end
  end
  
  handle(PendingTransactionCommands::AdjustPendingTransaction).with(Domain::PendingTransaction).using(:adjust)
  
  on PendingTransactionCommands::ApprovePendingTransaction do |cmd|
    begin_unit_of_work cmd.headers do |uow|
      transaction = uow.get_by_id Domain::PendingTransaction, cmd.aggregate_id
      account = uow.get_by_id Domain::Account, transaction.account_id
      transaction.approve account
    end
  end
  
  on PendingTransactionCommands::AdjustAndApprovePendingTransaction do |cmd|
    begin_unit_of_work cmd.headers do |uow|
      transaction = uow.get_by_id Domain::PendingTransaction, cmd.aggregate_id
      transaction.adjust amount: cmd.amount, date: cmd.date, tag_ids: cmd.tag_ids, comment: cmd.comment, account_id: cmd.account_id, type_id: cmd.type_id
      account = uow.get_by_id Domain::Account, transaction.account_id
      transaction.approve account
    end
  end
  
  handle(PendingTransactionCommands::RejectPendingTransaction).with(Domain::PendingTransaction).using(:reject)
end