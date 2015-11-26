require 'rails_helper'

describe Domain::Ledger do
  using LedgerHelpers
  module I
    include Domain::Events
  end
  let(:i) {
    Module.new do
      include Domain
    end
  }
  
  let(:currency) { currency = Currency['UAH'] }
  
  it "should be an aggregate" do
    expect(subject).to be_an_aggregate
  end
  
  describe "create" do
    it "should raise LedgerCreated event" do
      expect(CommonDomain::Aggregate).to receive(:new_id).and_return('ledger-1')
      subject.create 100, 'Ledger 1', currency
      expect(subject).to have_one_uncommitted_event I::LedgerCreated, aggregate_id: 'ledger-1', user_id: 100, name: 'Ledger 1', currency_code: currency.code
    end
    
    it "should return self" do
      expect(subject.create(100, 'Ledger 1', currency)).to be subject
    end
    
    it "should assign the id on LedgerCreated" do
      subject.apply_event I::LedgerCreated.new 'ledger-1', 100, 'Ledger 1', currency.code
      expect(subject.aggregate_id).to eql 'ledger-1'
    end
  end
  
  describe "rename" do
    before(:each) do
      subject.apply_event I::LedgerCreated.new 'ledger-1', 100, 'Ledger 1', currency.code
    end
    
    it "should raise LedgerRenamed event" do
      subject.rename 'New Ledger 20'
      expect(subject).to have_one_uncommitted_event I::LedgerRenamed, aggregate_id: 'ledger-1', name: 'New Ledger 20'
    end
  end
  
  describe "share" do
    before(:each) do
      subject.apply_event I::LedgerCreated.new 'ledger-1', 100, 'Ledger 1', currency.code
    end
    
    it "should share LedgerShared event" do
      subject.share User.new id: 200
      expect(subject).to have_one_uncommitted_event I::LedgerShared, aggregate_id: subject.aggregate_id, user_id: 200
    end
        
    it "should not share if already shared" do
      subject.apply_event I::LedgerShared.new 'ledger-1', 200
      subject.share User.new id: 200
      expect(subject).not_to have_uncommitted_events
    end
  end
  
  describe "create_new_account" do
    let(:account) { double(:account, aggregate_id: 'account-100')}
    before(:each) do
      subject.apply_event I::LedgerCreated.new 'ledger-1', 100, 'Ledger 1', currency.code
    end
    
    it "should create new account and return it raising AccountAddedToLedger event" do
      expect(Domain::Account).to receive(:new).and_return account
      currency = Currency['UAH']
      expect(account).to receive(:create).with('ledger-1', 
        i::Account::AccountId.new('a-1', 1), i::Account::InitialData.new('Account 100', '100.33', currency))
      expect(subject.create_new_account('a-1', i::Account::InitialData.new('Account 100', '100.33', currency))).to be account
      expect(subject).to have_one_uncommitted_event I::AccountAddedToLedger, aggregate_id: 'ledger-1', account_id: 'account-100'
    end
    
    it "should increment the sequential_number for each new account" do
      subject.apply_event I::AccountAddedToLedger.new 'ledger-1', 'account-100'
      subject.apply_event I::AccountAddedToLedger.new 'ledger-1', 'account-101'
      allow(Domain::Account).to receive(:new) { account }
      expect(account).to receive(:create).with('ledger-1', 
        i::Account::AccountId.new('a-1', 3), i::Account::InitialData.new('Account 100', '100.33', Currency['UAH']))
      subject.create_new_account('a-1', i::Account::InitialData.new('Account 100', '100.33', Currency['UAH']))
    end
    
    it "should raise error if account_id is not unique" do
      subject.apply_event I::AccountAddedToLedger.new 'ledger-1', 'account-100'
      expect {
        subject.create_new_account('account-100', i::Account::InitialData.new('', '0', Currency['UAH']))
      }.to raise_error ArgumentError, "account_id='account-100' is not unique"
    end
  end
  
  describe 'set_account_category' do
    let(:account) { double(:account, aggregate_id: 'account-100')}
    
    before(:each) do
      subject.apply_event I::LedgerCreated.new 'ledger-1', 100, 'Ledger 1', currency.code
      subject.apply_event I::AccountAddedToLedger.new 'ledger-1', 'account-100'
      subject.apply_event I::CategoryCreated.new subject.aggregate_id, 110, 0, 'Checking'
      subject.apply_event I::CategoryCreated.new subject.aggregate_id, 120, 1, 'Savings'
      subject.apply_event I::CategoryRemoved.new subject.aggregate_id, 120
    end
    
    it "should raise error if account is from different ledger" do
      different_account = double(:account, aggregate_id: 'account-110')
      expect(lambda { subject.set_account_category(different_account, 110) }).to raise_error("Account 'account-110' is not from ledger 'Ledger 1'.")
    end
    
    it "should raise error if unknown category" do
      expect(lambda { subject.set_account_category(account, 993) }).to raise_error("Category id='993' is not from ledger 'Ledger 1'.")
      expect(lambda { subject.set_account_category(account, 120) }).to raise_error("Category id='120' is not from ledger 'Ledger 1'.")
    end
    
    it 'should raise AccountCategoryAssigned event' do
      subject.set_account_category(account, 110)
      expect(subject).to have_one_uncommitted_event I::AccountCategoryAssigned, aggregate_id: subject.aggregate_id, 
        account_id: account.aggregate_id, category_id: 110
    end
        
    it 'should not raise AccountCategoryAssigned event if same category' do
      subject.apply_event I::AccountCategoryAssigned.new subject.aggregate_id, account.aggregate_id, 110
      subject.set_account_category(account, 110)
      expect(subject).not_to have_uncommitted_events
    end
  end 
  
  describe "close_account" do
    let(:account) { double(:account, aggregate_id: 'account-100') }
    before(:each) do
      subject.apply_event I::LedgerCreated.new 'ledger-1', 100, 'Ledger 1', currency.code
      subject.apply_event I::AccountAddedToLedger.new 'ledger-1', 'account-100'
    end
    
    it "should raise error if account is from different ledger" do
      different_account = double(:account, aggregate_id: 'account-110')
      expect(lambda { subject.close_account(different_account) }).to raise_error("Account 'account-110' is not from ledger 'Ledger 1'.")
    end
    
    it "should do nothing if already closed" do
      subject.apply_event I::LedgerAccountClosed.new 'ledger-1', 'account-100'
      subject.close_account account
      expect(subject).not_to have_uncommitted_events
      expect(account).not_to receive(:close)
    end
    
    it "should close the account and raise LedgerAccountClosed event" do
      expect(account).to receive(:close)
      subject.close_account account
      expect(subject).to have_one_uncommitted_event I::LedgerAccountClosed, aggregate_id: 'ledger-1', account_id: 'account-100'
    end
  end
  
  describe "reopen_account" do
    let(:account) { double(:account, aggregate_id: 'account-100') }
    before(:each) do
      subject.apply_event I::LedgerCreated.new 'ledger-1', 100, 'Ledger 1', currency.code
      subject.apply_event I::AccountAddedToLedger.new 'ledger-1', 'account-100'
      subject.apply_event I::LedgerAccountClosed.new 'ledger-1', 'account-100'
    end
    
    it "should raise error if account is from different ledger" do
      different_account = double(:account, aggregate_id: 'account-110')
      expect(lambda { subject.reopen_account(different_account) }).to raise_error("Account 'account-110' is not from ledger 'Ledger 1'.")
    end
    
    it "should raise error if not closed" do
      subject.apply_event I::AccountAddedToLedger.new 'ledger-1', 'account-110'
      expect { subject.reopen_account double(:account, aggregate_id: 'account-110')}.to raise_error "Account 'account-110' is not closed."
    end
    
    it "should reopen the account and raise LedgerAccountReopened event" do
      expect(account).to receive(:reopen)
      subject.reopen_account account
      expect(subject).to have_one_uncommitted_event I::LedgerAccountReopened, aggregate_id: 'ledger-1', account_id: 'account-100'
    end
  end
    
  describe "remove_account" do
    let(:account) { double(:account, aggregate_id: 'account-100') }
    before(:each) do
      subject.apply_event I::LedgerCreated.new 'ledger-1', 100, 'Ledger 1', currency.code
      subject.apply_event I::AccountAddedToLedger.new 'ledger-1', 'account-100'
      subject.apply_event I::LedgerAccountClosed.new 'ledger-1', 'account-100'
    end
    
    it "should raise error if account is from different ledger" do
      different_account = double(:account, aggregate_id: 'account-110')
      expect(lambda { subject.remove_account(different_account) }).to raise_error("Account 'account-110' is not from ledger 'Ledger 1'.")
    end
    
    it "should raise error if not closed" do
      subject.apply_event I::AccountAddedToLedger.new 'ledger-1', 'account-110'
      expect { subject.reopen_account double(:account, aggregate_id: 'account-110')}.to raise_error "Account 'account-110' is not closed."
    end
    
    it "should remove the account and raise LedgerAccountRemoved event" do
      expect(account).to receive(:remove)
      subject.remove_account account
      expect(subject).to have_one_uncommitted_event I::LedgerAccountRemoved, aggregate_id: 'ledger-1', account_id: 'account-100'
    end
  end
  
  describe "tags" do
    describe "create_tag" do
      before(:each) do
        subject.make_created
      end
    
      it "should raise TagCreatedEvent" do
        tag_id = subject.create_tag 'Food'
        expect(subject).to have_one_uncommitted_event I::TagCreated, aggregate_id: subject.aggregate_id, tag_id: tag_id, name: 'Food'
      end
    
      it "should increment tag_ids sequentally" do
        tag_id = subject.create_tag 'Food'
        expect(tag_id).to eql 1
        tag_id = subject.create_tag 'Lunch'
        expect(tag_id).to eql 2
        subject.apply_event I::TagCreated.new subject.aggregate_id, 5, 'Gas'
        tag_id = subject.create_tag 'Lunch'
        expect(tag_id).to eql 6
      end
    end
      
    describe "import_tag_with_id" do
      before(:each) do
        subject.make_created
      end
    
      it "should raise TagCreatedEvent" do
        subject.import_tag_with_id 22, 'Food'
        expect(subject).to have_one_uncommitted_event I::TagCreated, aggregate_id: subject.aggregate_id, tag_id: 22, name: 'Food'
      end
    
      it "should remember tag_id as last if it has last value" do
        subject.import_tag_with_id 22, 'Food'
        tag_id = subject.create_tag 'Lunch'
        expect(tag_id).to eql 23
      end
        
      it "should not remember tag_id as last if it has it has lower value" do
        subject.import_tag_with_id 22, 'Food'
        subject.import_tag_with_id 18, 'Food'
        tag_id = subject.create_tag 'Lunch'
        expect(tag_id).to eql 23
      end
    end
  
    describe "rename_tag" do
      it "should raise TagRenamedEvent" do
        subject.make_created.apply_event I::TagCreated.new subject.aggregate_id, 10001, 'Food'
        subject.rename_tag 10001, 'Food-1'
        expect(subject).to have_one_uncommitted_event I::TagRenamed, aggregate_id: subject.aggregate_id, tag_id: 10001, name: 'Food-1'
      end
    end
  
    describe "remove_tag" do
      it "should raise TagRemovedEvent" do
        subject.make_created.apply_event I::TagCreated.new subject.aggregate_id, 10001, 'Food'
        subject.remove_tag 10001
        expect(subject).to have_one_uncommitted_event I::TagRemoved, aggregate_id: subject.aggregate_id, tag_id: 10001
      end
    end
  end
  
  describe "categories" do
    describe "create_category" do
      before(:each) do
        subject.make_created
      end
    
      it "should raise CategoryCreatedEvent" do
        category_id = subject.create_category 'Food'
        expect(subject).to have_one_uncommitted_event I::CategoryCreated, aggregate_id: subject.aggregate_id, 
          category_id: category_id, display_order: 1, name: 'Food'
      end
    
      it "should increment category_ids sequentally" do
        category_id = subject.create_category 'Food'
        expect(category_id).to eql 1
        category_id = subject.create_category 'Lunch'
        expect(category_id).to eql 2
        subject.apply_event I::CategoryCreated.new subject.aggregate_id, 5, 0, 'Gas'
        category_id = subject.create_category 'Lunch'
        expect(category_id).to eql 6
      end
      
      it "should set initial display_order to max order + 1" do
        subject.apply_event I::CategoryCreated.new subject.aggregate_id, 1, 0, 'c 1'
        subject.apply_event I::CategoryCreated.new subject.aggregate_id, 2, 1, 'c 2'
        subject.apply_event I::CategoryCreated.new subject.aggregate_id, 3, 2, 'c 3'
        subject.create_category 'Lunch'
        expect(subject).to have_one_uncommitted_event I::CategoryCreated, aggregate_id: subject.aggregate_id, 
          category_id: 4, display_order: 3, name: 'Lunch'
      end
    end
    describe "import_category" do
      before(:each) do
        subject.make_created
      end
    
      it "should raise CategoryCreatedEvent" do
        subject.import_category 223, 200, 'Food'
        expect(subject).to have_one_uncommitted_event I::CategoryCreated, aggregate_id: subject.aggregate_id, 
          category_id: 223, display_order: 200, name: 'Food'
      end
    
      it "should remember last category id if it was last" do
        subject.import_category 223, 200, 'Food'
        category_id = subject.create_category 'Lunch'
        expect(category_id).to eql 224
      end
      
      it "should not remember last category id if it was not the latest" do
        subject.apply_event I::CategoryCreated.new subject.aggregate_id, 224, 0, 'c 1'
        subject.import_category 223, 200, 'Food'
        category_id = subject.create_category 'Lunch'
        expect(category_id).to eql 225
      end
      
      it "should set remember display_order" do
        subject.apply_event I::CategoryCreated.new subject.aggregate_id, 1, 0, 'c 1'
        subject.apply_event I::CategoryCreated.new subject.aggregate_id, 2, 1, 'c 2'
        subject.apply_event I::CategoryCreated.new subject.aggregate_id, 3, 2, 'c 3'
        subject.import_category 223, 200, 'Lunch'
        expect(subject).to have_one_uncommitted_event I::CategoryCreated, aggregate_id: subject.aggregate_id, 
          category_id: 223, display_order: 200, name: 'Lunch'
        subject.clear_uncommitted_events
        subject.create_category 'Car'
        expect(subject).to have_one_uncommitted_event I::CategoryCreated, aggregate_id: subject.aggregate_id, 
          category_id: 224, display_order: 201, name: 'Car'
      end
    end
  
    describe "rename_category" do
      it "should raise CategoryRenamedEvent" do
        subject.make_created.apply_event I::CategoryCreated.new subject.aggregate_id, 10001, 0, 'Food'
        subject.rename_category 10001, 'Food-1'
        expect(subject).to have_one_uncommitted_event I::CategoryRenamed, aggregate_id: subject.aggregate_id, category_id: 10001, name: 'Food-1'
      end
    end
  
    describe "remove_category" do
      it "should raise CategoryRemovedEvent" do
        subject.make_created.apply_event I::CategoryCreated.new subject.aggregate_id, 10001, 0, 'Food'
        subject.remove_category 10001
        expect(subject).to have_one_uncommitted_event I::CategoryRemoved, aggregate_id: subject.aggregate_id, category_id: 10001
      end
    end
  end
end