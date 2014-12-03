require 'rails_helper'

RSpec.describe Application::LedgersService, :type => :model do
  let(:repository) { double(:repository) }
  let(:repository_factory) { double(:repository_factory, create_repository: repository) }
  subject { described_class.new repository_factory }
  let(:i) {
    Module.new do
      include Projections
      include Application::Commands
    end
  }
  let(:ledger1) { double(:ledger1, aggregate_id: 'ledger-1') }
  
  describe "CreateNewAccount" do
    it "use the ledger to create the account" do
      cmd = i::LedgerCommands::CreateNewAccount.new 'ledger-1', 
        account_id: 'account-1332',
        name: 'Account 1223',
        initial_balance: '100.23',
        currency_code: 'UAH',
        unit: 'oz', 
        headers: dummy_headers
      initial_data = Domain::Account::InitialData.new('Account 1223', '100.23', Currency['UAH'], 'oz')
      expect(repository).to get_by_id(Domain::Ledger, 'ledger-1').and_return(ledger1).and_save(with_dummy_headers)
      account = double(:account, aggregate_id: 'account-1332')
      expect(ledger1).to receive(:create_new_account).with('account-1332', initial_data).and_return(account)
      expect(repository).to receive(:save).with(account, with_dummy_headers)
      subject.handle_message cmd
    end
  end
    
  describe "CloseAccount" do
    it "use the ledger to close the account" do
      cmd = i::LedgerCommands::CloseAccount.new 'ledger-1', account_id: 'account-1332', headers: dummy_headers
      account = double(:account)
      expect(repository).to get_by_id(Domain::Ledger, 'ledger-1').and_return(ledger1).and_save(with_dummy_headers)
      expect(repository).to get_by_id(Domain::Account, 'account-1332').and_return(account).and_save(with_dummy_headers)
      expect(ledger1).to receive(:close_account).with(account)
      subject.handle_message cmd
    end
  end
  
  describe "ReopenAccount" do
    it "use the ledger to reopen the account" do
      cmd = i::LedgerCommands::ReopenAccount.new 'ledger-1', account_id: 'account-1332', headers: dummy_headers
      account = double(:account)
      expect(repository).to get_by_id(Domain::Ledger, 'ledger-1').and_return(ledger1).and_save(with_dummy_headers)
      expect(repository).to get_by_id(Domain::Account, 'account-1332').and_return(account).and_save(with_dummy_headers)
      expect(ledger1).to receive(:reopen_account).with(account)
      subject.handle_message cmd
    end
  end
  
  describe "RemoveAccount" do
    it "use the ledger to remove the account" do
      cmd = i::LedgerCommands::RemoveAccount.new 'ledger-1', account_id: 'account-1332', headers: dummy_headers
      account = double(:account)
      expect(repository).to get_by_id(Domain::Ledger, 'ledger-1').and_return(ledger1).and_save(with_dummy_headers)
      expect(repository).to get_by_id(Domain::Account, 'account-1332').and_return(account).and_save(with_dummy_headers)
      expect(ledger1).to receive(:remove_account).with(account)
      subject.handle_message cmd
    end
  end
  
  describe "CreateTag" do
    it "use the ledger to create tag and return it's id" do
      cmd = i::LedgerCommands::CreateTag.new 'ledger-1', name: 'tag-1', headers: dummy_headers
      expect(repository).to get_by_id(Domain::Ledger, 'ledger-1').and_return(ledger1).and_save(with_dummy_headers)
      expect(ledger1).to receive(:create_tag).with('tag-1') { 22332 }
      expect(subject.handle_message cmd).to eql 22332
    end
  end
  
  describe "ImportTagWithId" do
    it "use the ledger to import the tag with id" do
      cmd = i::LedgerCommands::ImportTagWithId.new 'ledger-1', tag_id: 332, name: 'tag-1', headers: dummy_headers
      expect(repository).to get_by_id(Domain::Ledger, 'ledger-1').and_return(ledger1).and_save(with_dummy_headers)
      expect(ledger1).to receive(:import_tag_with_id).with(332, 'tag-1')
      subject.handle_message cmd
    end
  end
  
  describe "RenameTag" do
    it "use the ledger to rename tag" do
      cmd = i::LedgerCommands::RenameTag.new 'ledger-1', tag_id: 't-1', name: 'tag-1', headers: dummy_headers
      expect(repository).to get_by_id(Domain::Ledger, 'ledger-1').and_return(ledger1).and_save(with_dummy_headers)
      expect(ledger1).to receive(:rename_tag).with('t-1', 'tag-1')
      subject.handle_message cmd
    end
  end
  
  describe "RemoveTag" do
    it "use the ledger to remove tag" do
      cmd = i::LedgerCommands::RemoveTag.new 'ledger-1', tag_id: 't-1', headers: dummy_headers
      expect(repository).to get_by_id(Domain::Ledger, 'ledger-1').and_return(ledger1).and_save(with_dummy_headers)
      expect(ledger1).to receive(:remove_tag).with('t-1')
      subject.handle_message cmd
    end
  end
  
  describe "CreateCategory" do
    it "use the ledger to create category and return it's id" do
      cmd = i::LedgerCommands::CreateCategory.new 'ledger-1', name: 'category-1', headers: dummy_headers
      expect(repository).to get_by_id(Domain::Ledger, 'ledger-1').and_return(ledger1).and_save(with_dummy_headers)
      expect(ledger1).to receive(:create_category).with('category-1') { 22332 }
      expect(subject.handle_message cmd).to eql 22332
    end
  end
  
  describe "ImportCategory" do
    it "use the ledger to create category and return it's id" do
      cmd = i::LedgerCommands::ImportCategory.new 'ledger-1', category_id: 22332, display_order: 200, name: 'category-1', headers: dummy_headers
      expect(repository).to get_by_id(Domain::Ledger, 'ledger-1').and_return(ledger1).and_save(with_dummy_headers)
      expect(ledger1).to receive(:import_category).with(22332, 200, 'category-1')
      subject.handle_message cmd
    end
  end
  
  describe "RenameCategory" do
    it "use the ledger to rename category" do
      cmd = i::LedgerCommands::RenameCategory.new 'ledger-1', category_id: 'c-1', name: 'category-1', headers: dummy_headers
      expect(repository).to get_by_id(Domain::Ledger, 'ledger-1').and_return(ledger1).and_save(with_dummy_headers)
      expect(ledger1).to receive(:rename_category).with('c-1', 'category-1')
      subject.handle_message cmd
    end
  end
  
  describe "RemoveCategory" do
    it "use the ledger to remove category" do
      cmd = i::LedgerCommands::RemoveCategory.new 'ledger-1', category_id: 'c-1', headers: dummy_headers
      expect(repository).to get_by_id(Domain::Ledger, 'ledger-1').and_return(ledger1).and_save(with_dummy_headers)
      expect(ledger1).to receive(:remove_category).with('c-1')
      subject.handle_message cmd
    end
  end
  
  describe 'SetAccountCategory' do
    it 'should use the ledger to set account category' do
      cmd = i::LedgerCommands::SetAccountCategory.new 'ledger-1', account_id: 'account-1332', category_id: 'category-33223', headers: dummy_headers
      account = double(:account)
      expect(repository).to get_by_id(Domain::Ledger, 'ledger-1').and_return(ledger1).and_save(with_dummy_headers)
      expect(repository).to get_by_id(Domain::Account, 'account-1332').and_return(account).and_save(with_dummy_headers)
      expect(ledger1).to receive(:set_account_category).with(account, 'category-33223')
      subject.handle_message cmd
    end
  end
end