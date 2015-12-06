class Dev::DummyPendingTransactionsGenerator
  include Application::Commands::PendingTransactionCommands
  include CommonDomain

  def initialize(user, app)
    @dispatch_context = CommonDomain::DispatchCommand::DispatchContext::StaticDispatchContext.new user.id, '127.0.0.1'
    @user = user
    @app = app
  end

  @@fake_transactions_data = [
      {amount: '223.43', comment: 'Food for a week', type_id: Domain::Transaction::ExpenseTypeId},
      {amount: '325.01', comment: 'Food in class and some pizza', type_id: Domain::Transaction::ExpenseTypeId},
      {amount: '163.22', comment: 'Friends gave back', type_id: Domain::Transaction::RefundTypeId},
      {amount: '2300.91', comment: 'Monthly income', type_id: Domain::Transaction::IncomeTypeId},
      {amount: '620.32', comment: 'Gas and washing liquid'},
  ].freeze

  def generate(number)
    accounts = ::Projections::Account.get_user_accounts(@user)

    number.times do
      fake_data = @@fake_transactions_data[SecureRandom.random_number(@@fake_transactions_data.length)]
      account_number = SecureRandom.random_number(accounts.length + 1)
      account = account_number == accounts.length ? nil : accounts[account_number]
      Rails.logger.info "Generating pending transaction. Data: #{fake_data}, account: #{account}"
      report_pending_transaction account_id: account.try(:aggregate_id), amount: fake_data[:amount], comment: fake_data[:comment], type_id: fake_data[:type_id]
    end
  end

  def report_pending_transaction(account_id: nil, amount: nil, comment: nil, type_id: nil)
    dispatch ReportPendingTransaction.new id: Aggregate.new_id,
                                          user: @user,
                                          amount: amount,
                                          date: DateTime.now,
                                          tag_ids: [],
                                          comment: comment,
                                          account_id: account_id,
                                          type_id: type_id
  end

  private

  def dispatch(command)
    @app.command_dispatch_app.call command, @dispatch_context
  end
end