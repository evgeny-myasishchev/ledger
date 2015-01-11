class Dev::DummyPendingTransactionsGenerator
  include Application::Commands::PendingTransactionCommands
  include CommonDomain::Infrastructure
    
  def initialize(user, context)
    @dispatch_context = CommonDomain::DispatchCommand::DispatchContext::StaticDispatchContext.new user.id, '127.0.0.1'
    @user = user
    @context = context
  end
    
  def generate number
    dispatch ReportPendingTransaction.new AggregateId.new_id, user: @user, amount: '223.43', date: DateTime.now
    dispatch ReportPendingTransaction.new AggregateId.new_id, user: @user, amount: '223.43', date: DateTime.now
    dispatch ReportPendingTransaction.new AggregateId.new_id, user: @user, amount: '223.43', date: DateTime.now
    dispatch ReportPendingTransaction.new AggregateId.new_id, user: @user, amount: '223.43', date: DateTime.now
    
    @context.event_store.dispatcher.wait_pending
  end
    
  private def dispatch(command)
    @context.command_dispatch_middleware.call command, @dispatch_context
  end
end