require 'rails_helper'

RSpec.describe Projections::Transaction, :type => :model do
  subject { described_class.create_projection }
  let(:e) { Domain::Events }
  let(:p) { Projections }
  let(:income_id) { Domain::Transaction::IncomeTypeId }
  let(:expense_id) { Domain::Transaction::ExpenseTypeId }
  include AccountHelpers::P

  describe 'get_transfer_counterpart' do
    def new_transfer(id, &block)
      t = p::Transaction.new transaction_id: id, account_id: 'a-10', type_id: 1, amount: 10, is_transfer: true
      yield(t)
      t.save!
      t
    end

    let(:sending) { new_transfer 't-1' do |t|
      t.sending_transaction_id = t.transaction_id
    end }
    let(:receiving) { new_transfer 't-2' do |t|
      t.receiving_transaction_id = t.transaction_id
      t.sending_transaction_id = 't-1'
    end }

    before(:each) do
      # Doing so to have them initialized
      sending
      receiving
    end

    it 'should fail if the transaction is not transfer' do
      t = p::Transaction.create! transaction_id: 't-3', account_id: 'a-10', type_id: 1, amount: 10
      expect { t.get_transfer_counterpart }.to raise_error "Transaction 't-3' is not involved in transfer."
    end

    it 'should return receiving transaction if current is sending' do
      expect(sending.get_transfer_counterpart).to eql receiving
    end

    it 'should return sending transaction if current is receiving' do
      expect(receiving.get_transfer_counterpart).to eql sending
    end
  end

  describe 'self.get_root_data' do
    let(:user) {
      u = User.new
      u.id = 2233
      u
    }
    let(:date) { DateTime.now }
    let(:account) { create_account_projection! 'account-1', authorized_user_ids: '{100},{2233},{12233}' }
    before(:each) do
      subject.handle_message e::TransactionReported.new account.aggregate_id, 't-3', expense_id, 2000, date - 120, ['t-4'], 'Comment 103'
      subject.handle_message e::TransactionReported.new account.aggregate_id, 't-1', income_id, 10523, date - 100, ['t-1', 't-2'], 'Comment 101'
      subject.handle_message e::TransactionReported.new account.aggregate_id, 't-2', expense_id, 2000, date - 110, ['t-4'], 'Comment 102'

      allow(p::Account).to receive(:ensure_authorized!).with(account.aggregate_id, user) { account }
    end

    it 'should check if the user is authorized' do
      described_class.get_root_data user, account.aggregate_id
      expect(p::Account).to have_received(:ensure_authorized!).with(account.aggregate_id, user)
    end

    it 'should include account balance' do
      account.balance = 2233119
      account.save!
      data = described_class.get_root_data user, account.aggregate_id
      expect(data[:account_balance]).to eql(2233119)
    end

    it 'should get all transactions for the user using query builder' do
      query = double(:query)
      allow(query).to receive(:take) { query }
      allow(query).to receive(:count) { 100 }
      expect(described_class).to receive(:build_search_query).with(user, nil) { query }

      transactions = described_class.get_root_data(user, nil)[:transactions]
      expect(transactions).to be query
    end

    it 'should get all transactions for given account using query builder' do
      query = double(:query)
      allow(query).to receive(:take) { query }
      allow(query).to receive(:count) { 100 }
      expect(described_class).to receive(:build_search_query).with(user, account) { query }

      transactions = described_class.get_root_data(user, account.aggregate_id)[:transactions]
      expect(transactions).to be query
    end

    it 'should paginate and include pagination info' do
      query = double(:query)
      expect(query).to receive(:take).with(5) { query }
      expect(query).to receive(:count) { 20 }
      expect(described_class).to receive(:build_search_query).with(user, account) { query }
      data = described_class.get_root_data(user, account.aggregate_id, limit: 5)
      expect(data[:transactions_total]).to eql 20
      expect(data[:transactions_limit]).to eql 5
      expect(data[:transactions]).to be query
    end
  end

  describe 'self.search' do
    let(:user) { User.new id: 2233 }
    let(:date) { DateTime.now }
    let(:account) { create_account_projection! 'account-1', authorized_user_ids: '{100},{2233},{12233}' }
    let(:query) { double(:query) }
    before(:each) do
      subject.handle_message e::TransactionReported.new account.aggregate_id, 't-3', expense_id, 2000, date - 120, ['t-4'], 'Comment 103'
      subject.handle_message e::TransactionReported.new account.aggregate_id, 't-1', income_id, 10523, date - 100, ['t-1', 't-2'], 'Comment 101'
      subject.handle_message e::TransactionReported.new account.aggregate_id, 't-2', expense_id, 2000, date - 110, ['t-4'], 'Comment 102'

      allow(p::Account).to receive(:ensure_authorized!) { account }

      allow(query).to receive(:offset) { query }
      allow(query).to receive(:take) { query }
      allow(described_class).to receive(:build_search_query) { query }
    end

    it 'should check if the user is authorized' do
      described_class.search user, account.aggregate_id
      expect(p::Account).to have_received(:ensure_authorized!).with(account.aggregate_id, user)
    end

    it 'should build serach query for given account and criteria' do
      criteria = double(:criteria)
      expect(described_class).to receive(:build_search_query).with(user, account, criteria: criteria) { query }
      expect(described_class.search(user, account.aggregate_id, criteria: criteria)).to eql(transactions: query)
    end

    it 'should build search query for given user only if no account provided' do
      criteria = double(:criteria)
      expect(described_class).to receive(:build_search_query).with(user, nil, criteria: criteria) { query }
      expect(described_class.search(user, nil, criteria: criteria)).to eql(transactions: query)
    end

    it 'should use limit and offset' do
      expect(query).to receive(:offset).with(200) { query }
      expect(query).to receive(:take).with(23) { query }
      described_class.search(user, account.aggregate_id, offset: 200, limit: 23)
    end

    it 'should include total if required' do
      expect(query).to receive(:count).with(:id) { 23321 }
      result = described_class.search(user, account.aggregate_id, criteria: {}, with_total: true)
      expect(result[:transactions_total]).to eql 23321
    end
  end

  describe 'self.build_search_query' do
    let(:date) { DateTime.now }
    let(:user) { User.new id: 2233 }
    let(:account) { create_account_projection! 'account-1', authorized_user_ids: '{100},{2233},{12233}' }

    before(:each) do
      allow(p::Account).to receive(:ensure_authorized!) { account }

      subject.handle_message e::TransactionReported.new account.aggregate_id, 't-3', expense_id, 0, date - 110, ['tag-3'], ''
      subject.handle_message e::TransactionReported.new account.aggregate_id, 't-1', expense_id, 0, date, ['tag-1'], ''
      subject.handle_message e::TransactionReported.new account.aggregate_id, 't-2', expense_id, 0, date - 100, ['tag-2'], ''
    end

    it 'should fail if user and account are nil' do
      expect { described_class.build_search_query nil, nil }.to raise_error('User or Account should be provided.')
    end

    it 'should have required attributes' do
      result = described_class.build_search_query user, account
      expect_required_attributes result.first
    end

    it 'should treat null criteria as empty' do
      expect(described_class.build_search_query(user, account, criteria: nil).length).to eql 3
    end

    it 'should get all transactions of the user if no account provided' do
      a2 = create_account_projection! 'account-2', authorized_user_ids: '{2233},{993}'
      subject.handle_message e::TransactionReported.new a2.aggregate_id, 'ta-1', expense_id, 0, date, ['tag-1'], ''
      subject.handle_message e::TransactionReported.new a2.aggregate_id, 'ta-2', expense_id, 0, date, ['tag-1'], ''
      subject.handle_message e::TransactionReported.new a2.aggregate_id, 'ta-3', expense_id, 0, date, ['tag-1'], ''

      #Some fake stuff
      subject.handle_message e::TransactionReported.new 'fake-account-1', 'fake-1', expense_id, 0, date, ['tag-1'], ''
      subject.handle_message e::TransactionReported.new 'fake-account-1', 'fake-2', expense_id, 0, date, ['tag-1'], ''

      result = described_class.build_search_query user, nil
      expect(result.length).to eql 6
      expect(result.detect { |t| t.transaction_id == 'ta-1' }).not_to be_nil
      expect(result.detect { |t| t.transaction_id == 'ta-2' }).not_to be_nil
      expect(result.detect { |t| t.transaction_id == 'ta-3' }).not_to be_nil
    end

    it 'should order transactions by date descending' do
      transactions = described_class.build_search_query user, account
      expect(transactions[0].transaction_id).to eql 't-1'
      expect(transactions[1].transaction_id).to eql 't-2'
      expect(transactions[2].transaction_id).to eql 't-3'
    end

    it 'should filter by tag_ids' do
      result = described_class.build_search_query user, account, criteria: {tag_ids: ['tag-1', 'tag-2']}
      expect(result.length).to eql 2
      expect(result[0]).to eql described_class.find_by transaction_id: 't-1'
      expect(result[1]).to eql described_class.find_by transaction_id: 't-2'
    end

    it 'should filter by comment' do
      t1 = described_class.find_by transaction_id: 't-1'
      t1.comment = 'This is t-1 comment'
      t1.save!

      t2 = described_class.find_by transaction_id: 't-2'
      t2.comment = 'This is t-2 comment'
      t2.save!

      result = described_class.build_search_query user, account, criteria: {comment: 'is t-1'}
      expect(result.length).to eql 1
      expect(result[0]).to eql t1

      result = described_class.build_search_query user, account, criteria: {comment: 'This is'}
      expect(result.length).to eql 2
      expect(result[0]).to eql t1
      expect(result[1]).to eql t2
    end

    it 'should filter by comment case insensitive' do
      t1 = described_class.find_by transaction_id: 't-1'
      t1.comment = 'insensitive'
      t1.save!
      t2 = described_class.find_by transaction_id: 't-2'
      t2.comment = 'INSENSITIVE'
      t2.save!
      result = described_class.build_search_query user, account, criteria: {comment: 'INSENSITIVE'}
      expect(result.length).to eql 2
    end

    it 'should filter by exact amount' do
      t1 = described_class.find_by transaction_id: 't-1'
      t1.amount = 10023
      t1.save!

      t2 = described_class.find_by transaction_id: 't-2'
      t2.amount = 10023
      t2.save!

      result = described_class.build_search_query user, account, criteria: {amount: 10023}
      expect(result.length).to eql 2
      expect(result[0]).to eql t1
      expect(result[1]).to eql t2
    end

    it 'should filter by date from' do
      t1 = described_class.find_by transaction_id: 't-1'
      t1.date = date - 10
      t1.save!

      t2 = described_class.find_by transaction_id: 't-2'
      t2.date = date - 20
      t2.save!

      result = described_class.build_search_query user, account, criteria: {from: t2.date}
      expect(result.length).to eql 2
      expect(result[0]).to eql t1
      expect(result[1]).to eql t2

      result = described_class.build_search_query user, account, criteria: {from: t1.date}
      expect(result.length).to eql 1
      expect(result[0]).to eql t1
    end

    it 'should filter by date to' do
      t1 = described_class.find_by transaction_id: 't-1'
      t1.date = date - 10
      t1.save!

      t2 = described_class.find_by transaction_id: 't-2'
      t2.date = date - 20
      t2.save!

      t3 = described_class.find_by transaction_id: 't-3'
      t3.date = date - 30
      t3.save!

      result = described_class.build_search_query user, account, criteria: {to: t2.date}
      expect(result.length).to eql 2
      expect(result[0]).to eql t2
      expect(result[1]).to eql t3
    end
  end

  def expect_required_attributes(transaction)
    expect(transaction.attributes.keys).to eql %w(
    id transaction_id account_id type_id amount tag_ids comment date
    is_transfer sending_account_id sending_transaction_id receiving_account_id receiving_transaction_id
    reported_by reported_at)
  end

  describe 'add_tag' do
    subject { p::Transaction.new }
    before(:each) do
      subject.add_tag 100
      subject.add_tag 110
      subject.add_tag 120
    end

    it 'should add a tag wrapped in curly braces' do
      expect(subject.tag_ids).to eql '{100},{110},{120}'
    end

    it 'should mark the tag_ids as changed' do
      subject.clear_changes_information
      subject.add_tag 130
      expect(subject.tag_ids_changed?).to be_truthy
    end

    it 'should not add the tag_id if already present' do
      subject.changes_applied
      subject.add_tag 100
      expect(subject.tag_ids).to eql('{100},{110},{120}')
      expect(subject.tag_ids_changed?).to be_falsey
    end
  end

  describe 'remove_tag' do
    subject { p::Transaction.new }
    before(:each) do
      subject.tag_ids = '{100},{200},{300},{400},{500}'
      subject.clear_changes_information
      subject.remove_tag 100
    end

    it 'should remove the tag' do
      expect(subject.tag_ids).to eql '{200},{300},{400},{500}'
      subject.remove_tag 500
      expect(subject.tag_ids).to eql '{200},{300},{400}'
      subject.remove_tag 300
      expect(subject.tag_ids).to eql '{200},{400}'
    end

    it 'should mark the tag_ids as changed' do
      expect(subject.tag_ids_changed?).to be_truthy
    end

    it 'should do nothing if no such tag' do
      subject.tag_ids = "{100}"
      subject.clear_changes_information
      subject.remove_tag 300
      expect(subject.tag_ids).to eql '{100}'
      expect(subject.tag_ids_changed?).to be_falsy
    end
  end

  describe 'on PendingTransactionAdjusted' do
    it 'should insert new transaction with pending flag' do
      date1 = DateTime.now - 100
      date2 = date1 - 100
      subject.handle_message e::PendingTransactionAdjusted.new('t-1', 10523, date1, ['t-1', 't-2'], 'Comment 100', 'account-1', income_id)
      subject.handle_message e::PendingTransactionAdjusted.new('t-2', 2000, date2, ['t-3', 't-4'], 'Comment 101', 'account-1', expense_id)

      t1 = described_class.find_by_transaction_id 't-1'
      expect(t1.account_id).to eql('account-1')
      expect(t1.type_id).to eql(income_id)
      expect(t1.amount).to eql(10523)
      expect(t1.tag_ids).to eql '{t-1},{t-2}'
      expect(t1.comment).to eql 'Comment 100'
      expect(t1.date.to_datetime.to_json).to eql date1.utc.to_json
      expect(t1.is_pending).to be_truthy

      t2 = described_class.find_by_transaction_id 't-2'
      expect(t2.account_id).to eql('account-1')
      expect(t2.type_id).to eql(expense_id)
      expect(t2.amount).to eql(2000)
      expect(t2.tag_ids).to eql '{t-3},{t-4}'
      expect(t2.comment).to eql 'Comment 101'
      expect(t2.date.to_datetime.to_json).to eql date2.utc.to_json
      expect(t2.is_pending).to be_truthy
    end

    it 'should update existing transaction' do
      date1 = DateTime.now - 100
      date2 = date1 - 100
      subject.handle_message e::PendingTransactionReported.new('t-1', 100, 10523, date1, ['t-1', 't-2'], 'Comment 100', 'account-1', income_id)
      subject.handle_message e::PendingTransactionAdjusted.new('t-1', 2000, date2, ['t-3', 't-4'], 'Comment 101', 'account-2', expense_id)

      t1 = described_class.find_by_transaction_id 't-1'
      expect(t1.account_id).to eql('account-2')
      expect(t1.type_id).to eql(expense_id)
      expect(t1.amount).to eql(2000)
      expect(t1.tag_ids).to eql '{t-3},{t-4}'
      expect(t1.comment).to eql 'Comment 101'
      expect(t1.date.to_datetime.to_json).to eql date2.utc.to_json
      expect(t1.is_pending).to be_truthy
    end

    it 'should not insert if account_id is null' do
      subject.handle_message e::PendingTransactionAdjusted.new('t-1', 10523, DateTime.now, ['t-1', 't-2'], 'Comment 100', nil, income_id)
      t1 = described_class.find_by_transaction_id 't-1'
      expect(t1).to be_nil
    end

    it 'should delete if account_id got null' do
      date1 = DateTime.now - 100
      date2 = date1 - 100
      subject.handle_message e::PendingTransactionReported.new('t-1', 100, 10523, date1, ['t-1', 't-2'], 'Comment 100', 'account-1', income_id)
      subject.handle_message e::PendingTransactionAdjusted.new('t-1', 2000, date2, ['t-3', 't-4'], 'Comment 101', nil, expense_id)

      t1 = described_class.find_by_transaction_id 't-1'
      expect(t1).to be_nil
    end

    it 'should record user and reported date' do
      user = create(:user)
      commit_timestamp = DateTime.now - 100
      headers = {
          user_id: user.id,
          :$commit_timestamp => commit_timestamp
      }
      subject.handle_message e::PendingTransactionAdjusted.new('t-1', 10523, DateTime.now, ['t-1', 't-2'], 'Comment 100', 'account-100', income_id), headers
      t1 = described_class.find_by_transaction_id('t-1')
      expect(t1.reported_by_id).to eql user.id
      expect(t1.reported_by).to eql user.email
      expect(t1.reported_at.to_datetime.to_json).to eql commit_timestamp.utc.to_json
    end
  end

  describe 'on PendingTransactionReported' do
    it 'should insert new transaction with pending flag' do
      date1 = DateTime.now - 100
      date2 = date1 - 100
      subject.handle_message e::PendingTransactionReported.new('t-1', 100, 10523, date1, ['t-1', 't-2'], 'Comment 100', 'account-1', income_id)
      subject.handle_message e::PendingTransactionReported.new('t-2', 110, 2000, date2, ['t-3', 't-4'], 'Comment 101', 'account-1', expense_id)

      t1 = described_class.find_by_transaction_id 't-1'
      expect(t1.account_id).to eql('account-1')
      expect(t1.type_id).to eql(income_id)
      expect(t1.amount).to eql(10523)
      expect(t1.tag_ids).to eql '{t-1},{t-2}'
      expect(t1.comment).to eql 'Comment 100'
      expect(t1.date.to_datetime.to_json).to eql date1.utc.to_json
      expect(t1.is_pending).to be_truthy

      t2 = described_class.find_by_transaction_id 't-2'
      expect(t2.account_id).to eql('account-1')
      expect(t2.type_id).to eql(expense_id)
      expect(t2.amount).to eql(2000)
      expect(t2.tag_ids).to eql '{t-3},{t-4}'
      expect(t2.comment).to eql 'Comment 101'
      expect(t2.date.to_datetime.to_json).to eql date2.utc.to_json
      expect(t2.is_pending).to be_truthy
    end

    it 'should not insert if account_id is null' do
      date1 = DateTime.now - 100
      date2 = date1 - 100
      subject.handle_message e::PendingTransactionReported.new('t-1', 100, 10523, date1, ['t-1', 't-2'], 'Comment 100', nil, income_id)
      subject.handle_message e::PendingTransactionReported.new('t-2', 110, 2000, date2, ['t-3', 't-4'], 'Comment 101', nil, expense_id)

      t1 = described_class.find_by_transaction_id 't-1'
      expect(t1).to be_nil

      t2 = described_class.find_by_transaction_id 't-2'
      expect(t2).to be_nil
    end

    it 'should record user and reported date' do
      user = create(:user)
      commit_timestamp = DateTime.now - 100
      headers = {
          user_id: user.id,
          :$commit_timestamp => commit_timestamp
      }
      subject.handle_message e::PendingTransactionReported.new('t-1', 100, 10523, DateTime.new, ['t-1', 't-2'], 'Comment 100', 'account-1', income_id), headers
      t1 = described_class.find_by_transaction_id('t-1')
      expect(t1.reported_by_id).to eql user.id
      expect(t1.reported_by).to eql user.email
      expect(t1.reported_at.to_datetime.to_json).to eql commit_timestamp.utc.to_json
    end

    it 'should be idempotent' do
      subject.handle_message e::PendingTransactionReported.new('t-1', 100, 10523, DateTime.new, [], '', 'account-1', income_id)
      expect {
        subject.handle_message e::PendingTransactionReported.new('t-1', 100, 10523, DateTime.new, [], '', 'account-1', income_id)
      }.not_to change { described_class.count }
    end
  end

  describe 'on PendingTransactionApproved' do
    it 'should reset pending flag' do
      subject.handle_message e::PendingTransactionReported.new('t-1', 100, 10523, DateTime.now, ['t-1', 't-2'], 'Comment 100', 'account-1', income_id)
      subject.handle_message e::PendingTransactionApproved.new('t-1')

      t1 = described_class.find_by_transaction_id 't-1'
      expect(t1.is_pending).to be_falsy
    end
  end

  describe 'on PendingTransactionRejected' do
    it 'should remove pending transaction' do
      subject.handle_message e::PendingTransactionReported.new('t-1', 100, 10523, DateTime.now, ['t-1', 't-2'], 'Comment 100', 'account-1', income_id)
      subject.handle_message e::PendingTransactionRejected.new('t-1')

      t1 = described_class.find_by_transaction_id 't-1'
      expect(t1).to be_nil
    end

    it 'should be idempotent' do
      subject.handle_message e::PendingTransactionReported.new('t-1', 100, 10523, DateTime.now, ['t-1', 't-2'], 'Comment 100', 'account-1', income_id)
      subject.handle_message e::PendingTransactionRejected.new('t-1')
      expect {
        subject.handle_message e::PendingTransactionRejected.new('t-1')
      }.not_to change { described_class.count }
    end
  end

  describe 'on TransactionReported' do
    it 'should record the transaction' do
      date1 = DateTime.now - 100
      date2 = date1 - 100
      subject.handle_message e::TransactionReported.new 'account-1', 't-1', income_id, 10523, date1, ['t-1', 't-2'], 'Comment 100'
      subject.handle_message e::TransactionReported.new 'account-1', 't-2', expense_id, 2000, date2, ['t-3', 't-4'], 'Comment 101'

      t1 = described_class.find_by_transaction_id 't-1'
      expect(t1.account_id).to eql('account-1')
      expect(t1.type_id).to eql(income_id)
      expect(t1.amount).to eql(10523)
      expect(t1.tag_ids).to eql '{t-1},{t-2}'
      expect(t1.comment).to eql 'Comment 100'
      expect(t1.date.to_datetime.to_json).to eql date1.utc.to_json

      t2 = described_class.find_by_transaction_id 't-2'
      expect(t2.account_id).to eql('account-1')
      expect(t2.type_id).to eql(expense_id)
      expect(t2.amount).to eql(2000)
      expect(t2.tag_ids).to eql '{t-3},{t-4}'
      expect(t2.comment).to eql 'Comment 101'
      expect(t2.date.to_datetime.to_json).to eql date2.utc.to_json
    end

    it 'should record user and reported date' do
      user = create(:user)
      commit_timestamp = DateTime.now - 100
      headers = {
          user_id: user.id,
          :$commit_timestamp => commit_timestamp
      }
      subject.handle_message e::TransactionReported.new('account-1', 't-1', income_id, 10523, DateTime.now, [], nil), headers
      t1 = described_class.find_by_transaction_id('t-1')
      expect(t1.reported_by_id).to eql user.id
      expect(t1.reported_by).to eql user.email
      expect(t1.reported_at.to_datetime.to_json).to eql commit_timestamp.utc.to_json
    end

    it 'should be idempotent' do
      subject.handle_message e::TransactionReported.new 'account-1', 't-1', income_id, 10523, DateTime.now, [], nil
      expect {
        subject.handle_message e::TransactionReported.new 'account-1', 't-1', income_id, 10523, DateTime.now, [], nil
      }.not_to change { described_class.count }
    end

    it 'should update existing pending transaction' do
      date1 = DateTime.now - 100
      date2 = date1 - 100
      subject.handle_message e::PendingTransactionReported.new('t-1', 100, 10523, date1, ['t-1', 't-2'], 'Comment 100', 'account-1', income_id)
      subject.handle_message e::TransactionReported.new('account-2', 't-1', expense_id, 2000, date2, ['t-3', 't-4'], 'Comment 101')

      t1 = described_class.find_by_transaction_id 't-1'
      expect(t1.account_id).to eql('account-2')
      expect(t1.type_id).to eql(expense_id)
      expect(t1.amount).to eql(2000)
      expect(t1.tag_ids).to eql '{t-3},{t-4}'
      expect(t1.comment).to eql 'Comment 101'
      expect(t1.date.to_datetime.to_json).to eql date2.utc.to_json
    end
  end

  describe 'transfer' do
    let(:date) { DateTime.now - 100 }
    let(:t1) { described_class.find_by_transaction_id('t-1') }
    let(:t2) { described_class.find_by_transaction_id('t-2') }
    let(:commit_timestamp) { DateTime.now - 100 }
    let(:user) { create(:user) }
    let(:headers) { {user_id: user.id, :$commit_timestamp => commit_timestamp} }
    before(:each) do
      subject.handle_message e::TransferSent.new('account-1', 't-1', 'account-2', 10523, date, ['t-1', 't-2'], 'Comment 100'), headers
      subject.handle_message e::TransferReceived.new('account-2', 't-2', 'account-1', 't-1', 10523, date, ['t-1', 't-2'], 'Comment 100'), headers
    end

    describe 'on TransferSent' do
      it 'should record the transaction as expense' do
        expect(t1.account_id).to eql('account-1')
        expect(t1.transaction_id).to eql('t-1')
        expect(t1.type_id).to eql(expense_id)
        expect(t1.amount).to eql(10523)
        expect(t1.tag_ids).to eql '{t-1},{t-2}'
        expect(t1.comment).to eql 'Comment 100'
        expect(t1.date.to_datetime.to_json).to eql date.utc.to_json
      end

      it 'should record transfer related attributes' do
        expect(t1.is_transfer).to be_truthy
        expect(t1.sending_account_id).to eql('account-1')
        expect(t1.sending_transaction_id).to eql('t-1')
        expect(t1.receiving_account_id).to eql('account-2')
      end

      it 'should record user and reported date' do
        expect(t1.reported_by_id).to eql user.id
        expect(t1.reported_by).to eql user.email
        expect(t1.reported_at.to_datetime.to_json).to eql commit_timestamp.utc.to_json
      end

      it 'should be idempotent' do
        expect {
          subject.handle_message e::TransferSent.new 'account-1', 't-1', 'account-2', 10523, date, ['t-1', 't-2'], 'Comment 100'
        }.not_to change { described_class.count }
      end
    end

    describe 'on TransferReceived' do
      it 'should record the transaction as income' do
        expect(t2.account_id).to eql('account-2')
        expect(t2.transaction_id).to eql('t-2')
        expect(t2.type_id).to eql(income_id)
        expect(t2.amount).to eql(10523)
        expect(t2.tag_ids).to eql '{t-1},{t-2}'
        expect(t2.comment).to eql 'Comment 100'
        expect(t2.date.to_datetime.to_json).to eql date.utc.to_json
      end

      it 'should record transfer related attributes' do
        expect(t2.is_transfer).to be_truthy
        expect(t2.sending_account_id).to eql('account-1')
        expect(t2.sending_transaction_id).to eql('t-1')
        expect(t2.receiving_account_id).to eql('account-2')
        expect(t2.receiving_transaction_id).to eql('t-2')
      end

      it 'should record user and reported date' do
        expect(t1.reported_by_id).to eql user.id
        expect(t1.reported_by).to eql user.email
        expect(t1.reported_at.to_datetime.to_json).to eql commit_timestamp.utc.to_json
      end

      it 'should be idempotent' do
        expect {
          subject.handle_message e::TransferReceived.new 'account-2', 't-2', 'account-1', 't-1', 10523, date, ['t-1', 't-2'], 'Comment 100'
        }.not_to change { described_class.count }
      end
    end
  end

  describe 'adjustments' do
    let(:date) { DateTime.now - 100 }
    let(:t1) { p::Transaction.find_by_transaction_id 't-1' }
    before(:each) do
      subject.handle_message e::TransactionReported.new 'account-1', 't-1', expense_id, 2000, date, [100, 200], 'Comment 1'
    end

    it 'should update amount on TransactionAmountAdjusted' do
      subject.handle_message e::TransactionAmountAdjusted.new 'account-1', 't-1', 1900
      expect(t1.amount).to eql 1900
    end

    it 'should update comment on TransactionCommentAdjusted' do
      subject.handle_message e::TransactionCommentAdjusted.new 'account-1', 't-1', 'New comment 1'
      expect(t1.comment).to eql 'New comment 1'
    end

    it 'should update date on TransactionDateAdjusted' do
      updated_date = date - 110
      subject.handle_message e::TransactionDateAdjusted.new 'account-1', 't-1', updated_date
      expect(t1.date.to_datetime.to_json).to eql updated_date.utc.to_json
    end

    it 'should add new tag on TransactionTagged' do
      subject.handle_message e::TransactionTagged.new 'account-1', 't-1', 110
      expect(t1.tag_ids).to eql '{100},{200},{110}'
    end

    it 'should add new tag on TransactionUntagged' do
      subject.handle_message e::TransactionUntagged.new 'account-1', 't-1', 100
      expect(t1.tag_ids).to eql '{200}'
      subject.handle_message e::TransactionUntagged.new 'account-1', 't-1', 200
      t1.reload
      expect(t1.tag_ids).to eql ''
    end

    describe 'on TransactionRemoved' do
      it 'should remove the transaction' do
        subject.handle_message e::TransactionRemoved.new 'account-1', 't-1'
        expect(t1).to be_nil
      end

      it 'should be idempotent' do
        subject.handle_message e::TransactionRemoved.new 'account-1', 't-1'
        expect {
          subject.handle_message e::TransactionRemoved.new 'account-1', 't-1'
        }.not_to change { described_class.count }
      end
    end
  end

  describe 'on TransactionTypeConverted' do
    let(:account1) { create_account_projection! 'account-1', authorized_user_ids: '{100}' }

    it 'should update transaction type' do
      subject.handle_message e::TransactionReported.new account1.aggregate_id, 't-1', expense_id, 2000, DateTime.now, [], ''
      subject.handle_message e::TransactionReported.new account1.aggregate_id, 't-2', income_id, 10523, DateTime.now, [], ''

      subject.handle_message e::TransactionTypeConverted.new account1.aggregate_id, 't-1', income_id
      subject.handle_message e::TransactionTypeConverted.new account1.aggregate_id, 't-2', expense_id

      expect(p::Transaction.find_by_transaction_id('t-1').type_id).to eql income_id
      expect(p::Transaction.find_by_transaction_id('t-2').type_id).to eql expense_id
    end
  end

  describe 'on AccountRemoved' do
    let(:account1) { create_account_projection! 'account-1', authorized_user_ids: '{100}' }
    let(:account2) { create_account_projection! 'account-2', authorized_user_ids: '{100}' }

    before(:each) do
      date = DateTime.now
      subject.handle_message e::TransactionReported.new account1.aggregate_id, 't-1', expense_id, 2000, date - 120, ['t-4'], 'Comment 103'
      subject.handle_message e::TransactionReported.new account1.aggregate_id, 't-2', income_id, 10523, date - 100, ['t-1', 't-2'], 'Comment 101'
      subject.handle_message e::TransactionReported.new account1.aggregate_id, 't-3', expense_id, 2000, date - 110, ['t-4'], 'Comment 102'
      subject.handle_message e::TransactionReported.new account2.aggregate_id, 't-4', expense_id, 2000, date - 110, ['t-4'], 'Comment 102'
      subject.handle_message e::TransactionReported.new account2.aggregate_id, 't-5', expense_id, 2000, date - 110, ['t-4'], 'Comment 102'
      subject.handle_message e::TransactionReported.new account2.aggregate_id, 't-6', expense_id, 2000, date - 110, ['t-4'], 'Comment 102'
      subject.handle_message e::AccountRemoved.new account1.aggregate_id
    end

    it 'should remove all belonging transactions' do
      expect(p::Transaction.where(account_id: account1.aggregate_id).length).to eql 0
    end

    it 'should not affect other transactions' do
      expect(p::Transaction.where(account_id: account2.aggregate_id).length).to eql 3
    end
  end
end
