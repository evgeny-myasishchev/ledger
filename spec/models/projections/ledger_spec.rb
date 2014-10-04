require 'rails_helper'

RSpec.describe Projections::Ledger, :type => :model do
  include AccountHelpers::P
  
  subject { described_class.create_projection }
  let(:e) { Domain::Events }
  let(:p) { Projections }
  let(:currency) { currency = Currency['UAH'] }

  before(:each) do
    subject.handle_message e::LedgerCreated.new 'ledger-1', 100, 'Ledger 1', currency.code
  end
  
  let(:ledger_1) { ledger = described_class.find_by_aggregate_id 'ledger-1' }
  
  describe "self.get_user_ledgers" do
    it "should return ledgers owed by the user" do
      l1 = p::Ledger.create! aggregate_id: 'l-1', owner_user_id: 11222, name: 'Ledger 1', shared_with_user_ids: nil, currency_code: currency.code
      l2 = p::Ledger.create! aggregate_id: 'l-2', owner_user_id: 11222, name: 'Ledger 2', shared_with_user_ids: nil, currency_code: currency.code
      l3 = p::Ledger.create! aggregate_id: 'l-3', owner_user_id: 11223, name: 'Ledger 3', shared_with_user_ids: nil, currency_code: currency.code
      expect(p::Ledger.get_user_ledgers(User.new id: 11222)).to eql([l1, l2])
      expect(p::Ledger.get_user_ledgers(User.new id: 11223)).to eql([l3])
    end
    
    it "should load limited set of attributes only" do
      l1 = p::Ledger.create! aggregate_id: 'l-1', owner_user_id: 11222, name: 'Ledger 1', shared_with_user_ids: nil, currency_code: currency.code
      actual_l1 = p::Ledger.get_user_ledgers(User.new id: 11222).first
      expect(actual_l1.attribute_names).to eql ['id', 'aggregate_id', 'name', 'currency_code']
    end
  end
  
  describe 'self.get_rates' do
    let(:user) { User.new id: ledger_1.owner_user_id }
    before(:each) do
      allow(CurrencyRate).to receive(:get) { double(:rates) }
    end
    
    it 'should ensure the user is authorized' do
      expect(ledger_1).to receive(:ensure_authorized!).with(user)
      ledger_1.get_rates user
    end
    
    it 'should get rates for all accounts of the ledger' do
      a1 = create_account_projection! 'a1', ledger_1.aggregate_id, ledger_1.owner_user_id, currency_code: currency.code
      a2 = create_account_projection! 'a2', ledger_1.aggregate_id, ledger_1.owner_user_id, currency_code: 'USD'
      a3 = create_account_projection! 'a3', ledger_1.aggregate_id, ledger_1.owner_user_id, currency_code: 'EUR'
      
      from_rates = lambda { |from_rates| 
        expect(from_rates.length).to eql 2
        expect(from_rates).to include 'USD'
        expect(from_rates).to include 'EUR'
        true
      }
      
      rates = double(:rates)
      expect(CurrencyRate).to receive(:get).with(from: from_rates, to: 'UAH').and_return rates
      expect(described_class.get_rates(user, ledger_1.aggregate_id)).to eql rates
    end
    
    it 'should skip rates of accounts from different ledger' do
      create_account_projection! 'a1', ledger_1.aggregate_id, ledger_1.owner_user_id, currency_code: 'AUD'
      create_account_projection! 'a2', 'l-2', ledger_1.owner_user_id, currency_code: 'USD'
      create_account_projection! 'a3', 'l-2', ledger_1.owner_user_id, currency_code: 'EUR'
      
      rates = double(:rates)
      expect(CurrencyRate).to receive(:get).with(from: ['AUD'], to: 'UAH').and_return rates
      described_class.get_rates(user, ledger_1.aggregate_id)
    end
    
    it 'should skip rates of unauthorized accounts' do
      create_account_projection! 'a1', ledger_1.aggregate_id, ledger_1.owner_user_id, currency_code: 'AUD'
      create_account_projection! 'a2', ledger_1.aggregate_id, ledger_1.owner_user_id, authorized_user_ids: "{110}", currency_code: 'USD'
      create_account_projection! 'a3', ledger_1.aggregate_id, ledger_1.owner_user_id, authorized_user_ids: "{110}", currency_code: 'EUR'
      
      rates = double(:rates)
      expect(CurrencyRate).to receive(:get).with(from: ['AUD'], to: 'UAH').and_return rates
      described_class.get_rates(user, ledger_1.aggregate_id)
    end
  end
  
  describe 'ensure_authorized!' do
    it 'should do nothing if the user is owner' do
      expect { ledger_1.ensure_authorized! User.new id: 100 }.not_to raise_error
    end
    
    it 'should do nothing if the ledger is shared with the user' do
      ledger_1.shared_with_user_ids.add 110
      expect { ledger_1.ensure_authorized! User.new id: 100 }.not_to raise_error
    end
    
    it 'should raise AuthorizationFailedError if the user is not owner or not shared' do
      ledger_1.shared_with_user_ids.add 110
      expect { ledger_1.ensure_authorized! User.new id: 120 }.to raise_error Errors::AuthorizationFailedError
    end
  end
  
  describe "authorized_user_ids" do
    it "should return an array of all users that are authorized to access the ledger" do
      ledger = p::Ledger.create!(aggregate_id: 'ledger-2', owner_user_id: 22331, shared_with_user_ids: Set.new([22332, 22333]), name: 'ledger 1', currency_code: currency.code)
      expect(ledger.authorized_user_ids).to eql([22332, 22333, 22331])
    end
  end
  
  describe "on LedgerCreated" do
    it "should create corresponding ledger record" do
      ledger_1 = described_class.find_by aggregate_id: 'ledger-1'
      expect(ledger_1.name).to eql 'Ledger 1'
      expect(ledger_1.owner_user_id).to eql 100
    end
    
    it "should be idempotent" do
      expect { subject.handle_message e::LedgerCreated.new 'ledger-1', 100, 'Ledger 1', currency.code }.not_to change { described_class.count }
    end
  end
  
  describe "on LedgerRenamed" do
    it "should rename the ledger" do
      subject.handle_message e::LedgerRenamed.new 'ledger-1', 'Ledger 110'
    end
  end
  
  describe "on LedgerShared" do
    before(:each) do
      subject.handle_message e::LedgerShared.new 'ledger-1', 120
      subject.handle_message e::LedgerShared.new 'ledger-1', 130
    end
    
    it "should record corresponding user_id" do
      expect(ledger_1.shared_with_user_ids).to eql Set.new([120, 130])
    end
    
    it "should be idempotent" do
      subject.handle_message e::LedgerShared.new 'ledger-1', 120
      expect(ledger_1.shared_with_user_ids).to eql Set.new([120, 130])
    end
  end

end
