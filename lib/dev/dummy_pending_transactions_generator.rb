class Dev::DummyPendingTransactionsGenerator
  include Application::Commands::PendingTransactionCommands
  include CommonDomain
    
  def initialize(user, app)
    @dispatch_context = CommonDomain::DispatchCommand::DispatchContext::StaticDispatchContext.new user.id, '127.0.0.1'
    @user = user
    @app = app
  end
    
  def generate number
    dispatch ReportPendingTransaction.new id: Aggregate.new_id, user: @user, amount: '223.43', date: DateTime.now, tag_ids: [], comment: nil, account: nil, type_id: Domain::Transaction::ExpenseTypeId
    dispatch ReportPendingTransaction.new id: Aggregate.new_id, user: @user, amount: '100.02', date: DateTime.now, tag_ids: [], comment: nil, account: nil, type_id: nil
    dispatch ReportPendingTransaction.new id: Aggregate.new_id, user: @user, amount: '95.32', date: DateTime.now, tag_ids: [], comment: nil, account: nil, type_id: nil
    dispatch ReportPendingTransaction.new id: Aggregate.new_id, user: @user, amount: '113.93', date: DateTime.now, comment: 'Food in class'
  end
    
  private def dispatch(command)
    @app.command_dispatch_app.call command, @dispatch_context
  end
end