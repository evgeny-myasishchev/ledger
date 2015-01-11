require 'rails_helper'

describe Application::Commands do
  describe Application::Commands::IncomeExpenceCommandFactory do
    let(:described_class) {
      Class.new(CommonDomain::Command) do
        include Application::Commands::IncomeExpenceCommandFactory
        attr_reader :amount, :date, :tag_ids, :comment
      end
    }
  
    describe "build_from_params" do
      let(:params) { Hash.new }
      let(:date) { 
        d = (DateTime.now - 100)
        d = d.iso8601
        DateTime.iso8601 d
      }
      before(:each) do
        params[:account_id] = 'account-993'
        params[:command] = {
          transaction_id: 'transaction-100',
          amount: '22110',
          date: date.iso8601
        }
      end
    
      subject { described_class.build_from_params params }
    
      it "should extract the and assign the aggregate_id from account_id" do
        expect(subject.aggregate_id).to eql 'account-993'
      end
    
      it "should fail if the account_id is not specified" do
        params[:account_id] = nil
        expect{subject}.to raise_error ArgumentError, 'account_id is missing'
      end
      
      it "shold fail if transaction_id is missing" do
        expect { described_class.build_from_params({
          account_id: 'account-100', command: {amount: 100, date: DateTime.now}
        }) }.to raise_error ArgumentError, 'transaction_id is missing'
      end
    
      it "should assign command attributes" do
        params[:command][:tag_ids] = ['t-1', 't-2']
        params[:command][:comment] = 'Command comment 201120'
        expect(subject.amount).to eql '22110'
        expect(subject.date).not_to be_nil
        expect(subject.tag_ids).to eql ['t-1', 't-2']
        expect(subject.comment).to eql 'Command comment 201120'
      end
    
      it "should parse the date from ISO 8601 format" do
        expect(subject.date).to eql date
      end
    
      it "should fail if amount is not specified" do
        params[:command][:amount] = nil
        expect{subject}.to raise_error ArgumentError, 'amount is missing'
      end
    
      it "should fail if date is not specified" do
        params[:command][:date] = nil
        expect{subject}.to raise_error ArgumentError, 'date is missing'
      end
    end
  end
  
  shared_examples 'a command with required aggregate_id and account_id' do
    it "shold validate presence of aggregate_id" do
      subject = described_class.from_hash Hash.new
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:aggregate_id]).to eql ["can't be blank"]
      expect(subject.errors[:account_id]).to eql ["can't be blank"]
      subject = described_class.from_hash aggregate_id: 'aggregate-1', account_id: 'account-1'
      expect(subject.valid?).to be_truthy
      expect(subject.aggregate_id).to eql 'aggregate-1'
      expect(subject.account_id).to eql 'account-1'
    end
  end
  
  describe described_class::TransferCommandFactory do
    let(:described_class) {
      Class.new(CommonDomain::Command) do
        include Application::Commands::TransferCommandFactory
        attr_reader :sending_transaction_id, :receiving_transaction_id, :receiving_account_id, :amount_sent, :amount_received, :date, :tag_ids, :comment
      end
    }
  
    describe "build_from_params" do
      let(:params) { Hash.new }
      let(:date) { 
        d = (DateTime.now - 100)
        d = d.iso8601
        DateTime.iso8601 d
      }
      before(:each) do
        params[:account_id] = 'sending-993'
        params[:command] = {
          sending_transaction_id: 'transaction-101',
          receiving_transaction_id: 'transaction-102',
          receiving_account_id: 'receiving-2291',
          amount_sent: '22110',
          amount_received: '100110',
          date: date.iso8601
        }
      end
    
      subject { described_class.build_from_params params }
    
      it "should assign command attributes" do
        params[:command][:tag_ids] = ['t-1', 't-2']
        params[:command][:comment] = 'Command comment 201120'
        expect(subject.aggregate_id).to eql 'sending-993'
        expect(subject.sending_transaction_id).to eql 'transaction-101'
        expect(subject.receiving_transaction_id).to eql 'transaction-102'
        expect(subject.receiving_account_id).to eql 'receiving-2291'
        expect(subject.amount_sent).to eql '22110'
        expect(subject.amount_received).to eql '100110'
        expect(subject.date).to eql date
        expect(subject.tag_ids).to eql ['t-1', 't-2']
        expect(subject.comment).to eql 'Command comment 201120'
      end
      
      it "shold fail if sending or receiving transaction_id is not present" do
        params[:command][:sending_transaction_id] = nil
        expect{subject}.to raise_error ArgumentError, 'sending_transaction_id is missing'
        
        params[:command][:sending_transaction_id] = 't-1'
        params[:command][:receiving_transaction_id] = nil
        expect{subject}.to raise_error ArgumentError, 'receiving_transaction_id is missing'
      end
      
      
      it "should fail if the account_id is not specified" do
        params[:account_id] = nil
        expect{subject}.to raise_error ArgumentError, 'account_id is missing'
      end
      
      it "should fail if the receiving_account_id is not specified" do
        params[:command][:receiving_account_id] = nil
        expect{subject}.to raise_error ArgumentError, 'receiving_account_id is missing'
      end
    
      it "should fail if amount_sent is not specified" do
        params[:command][:amount_sent] = nil
        expect{subject}.to raise_error ArgumentError, 'amount_sent is missing'
      end
    
      it "should fail if amount_received is not specified" do
        params[:command][:amount_received] = nil
        expect{subject}.to raise_error ArgumentError, 'amount_received is missing'
      end
    
      it "should fail if date is not specified" do
        params[:command][:date] = nil
        expect{subject}.to raise_error ArgumentError, 'date is missing'
      end
    end
  end
  
  describe described_class::AccountCommands do
    describe described_class::ReportIncome do
      it "should include the IncomeExpenceCommandFactory" do
        expect(subject).to be_a(Application::Commands::IncomeExpenceCommandFactory)
      end
    end
  
    describe described_class::ReportExpence do
      it "should include the IncomeExpenceCommandFactory" do
        expect(subject).to be_a(Application::Commands::IncomeExpenceCommandFactory)
      end
    end
  
    describe described_class::ReportRefund do
      it "should include the IncomeExpenceCommandFactory" do
        expect(subject).to be_a(Application::Commands::IncomeExpenceCommandFactory)
      end
    end
    
    describe described_class::ReportTransfer do
      it "should include the TransferCommandFactory" do
        expect(subject).to be_a(Application::Commands::TransferCommandFactory)
      end
    end
  
    describe described_class::AdjustAmount do
      it "should initialize the command from params" do
        subject = described_class.new transaction_id: 't-100', command: {amount: '100.5'}
        expect(subject.transaction_id).to eql('t-100')
        expect(subject.amount).to eql('100.5')
      end
    
      it "should validate presentce of transaction_id and amount" do
        subject = described_class.new command: {}
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:transaction_id]).to eql ["can't be blank"]
        expect(subject.errors[:amount]).to eql ["can't be blank"]
      end
    end
  
    describe described_class::AdjustTags do
      it "should initialize the command from params" do
        subject = described_class.new transaction_id: 't-100', command: {tag_ids: [100, 200]}
        expect(subject.transaction_id).to eql('t-100')
        expect(subject.tag_ids).to eql([100, 200])
      end
    
      it "should validate presentce of transaction_id" do
        subject = described_class.new command: {}
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:transaction_id]).to eql ["can't be blank"]
      end
    end
  
    describe described_class::AdjustDate do
      it "should initialize the command from params" do
        date = DateTime.new
        subject = described_class.new transaction_id: 't-100', command: {date: date}
        expect(subject.transaction_id).to eql('t-100')
        expect(subject.date).to eql(date)
      end
    
      it "should validate presentce of transaction_id and date" do
        subject = described_class.new command: {}
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:transaction_id]).to eql ["can't be blank"]
        expect(subject.errors[:date]).to eql ["can't be blank"]
      end
    end
  
    describe described_class::AdjustComment do
      it "should initialize the command from params" do
        subject = described_class.new transaction_id: 't-100', command: {comment: 'New comment'}
        expect(subject.transaction_id).to eql('t-100')
        expect(subject.comment).to eql('New comment')
      end
    
      it "should validate presentce of transaction_id" do
        subject = described_class.new command: {}
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:transaction_id]).to eql ["can't be blank"]
      end
    end
  
    describe described_class::RemoveTransaction do
      it "should initialize the command from params" do
        subject = described_class.new id: 't-100'
        expect(subject.transaction_id).to eql('t-100')
      end
    
      it "should validate presentce of transaction_id" do
        subject = described_class.new Hash.new
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:transaction_id]).to eql ["can't be blank"]
      end
    end
    
    describe described_class::RenameAccount do
      it "shold validate presence of all attributes" do
        subject = described_class.from_hash Hash.new
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:aggregate_id]).to eql ["can't be blank"]
        expect(subject.errors[:name]).to eql ["can't be blank"]
        subject = described_class.from_hash aggregate_id: 'l-1', name: 'New name'
        expect(subject.valid?).to be_truthy
      end
    end
    
    describe described_class::SetAccountUnit do
      it "shold validate presence aggregate_id" do
        subject = described_class.from_hash Hash.new
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:aggregate_id]).to eql ["can't be blank"]
        
        subject = described_class.from_hash aggregate_id: 'l-1', unit: 'oz'
        expect(subject.valid?).to be_truthy
      end
    end
  end
  
  describe described_class::LedgerCommands do
    describe described_class::CreateNewAccount do
      it "should vlaidate presence of all attributes" do
        subject = described_class.from_hash Hash.new
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:aggregate_id]).to eql ["can't be blank"]
        expect(subject.errors[:account_id]).to eql ["can't be blank"]
        expect(subject.errors[:name]).to eql ["can't be blank"]
        expect(subject.errors[:initial_balance]).to eql ["can't be blank"]
        expect(subject.errors[:currency_code]).to eql ["can't be blank"]
        
        subject = described_class.from_hash aggregate_id: 'l-1', account_id: 'a-1', name: 'a-1-name', initial_balance: 100, currency_code: 'uah'
        expect(subject.valid?).to be_truthy
      end
    end
    
    describe described_class::CloseAccount do
      it_behaves_like 'a command with required aggregate_id and account_id'
    end
    
    describe described_class::ReopenAccount do
      it_behaves_like 'a command with required aggregate_id and account_id'
    end
    
    describe described_class::RemoveAccount do
      it_behaves_like 'a command with required aggregate_id and account_id'
    end
    
    describe described_class::CreateTag do
      it "shold validate presence of aggregate_id and name" do
        subject = described_class.from_hash Hash.new
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:aggregate_id]).to eql ["can't be blank"]
        expect(subject.errors[:name]).to eql ["can't be blank"]
        subject = described_class.from_hash aggregate_id: 'l-1', name: 'tag-1'
        expect(subject.valid?).to be_truthy
        expect(subject.aggregate_id).to eql 'l-1'
        expect(subject.name).to eql 'tag-1'
      end
    end
    
    describe described_class::RenameTag do
      it "shold validate presence of aggregate_id, tag_id and name" do
        subject = described_class.from_hash Hash.new
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:aggregate_id]).to eql ["can't be blank"]
        expect(subject.errors[:tag_id]).to eql ["can't be blank"]
        expect(subject.errors[:name]).to eql ["can't be blank"]
        subject = described_class.from_hash aggregate_id: 'l-1', tag_id: 't-1', name: 'tag-1'
        expect(subject.valid?).to be_truthy
        expect(subject.aggregate_id).to eql 'l-1'
        expect(subject.tag_id).to eql 't-1'
        expect(subject.name).to eql 'tag-1'
      end
    end
    
    describe described_class::RemoveTag do
      it "shold validate presence of aggregate_id, tag_id" do
        subject = described_class.from_hash Hash.new
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:aggregate_id]).to eql ["can't be blank"]
        expect(subject.errors[:tag_id]).to eql ["can't be blank"]
        subject = described_class.from_hash aggregate_id: 'l-1', tag_id: 't-1'
        expect(subject.valid?).to be_truthy
        expect(subject.aggregate_id).to eql 'l-1'
        expect(subject.tag_id).to eql 't-1'
      end
    end
    
    describe described_class::CreateCategory do
      it "shold validate presence of aggregate_id and name" do
        subject = described_class.from_hash Hash.new
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:aggregate_id]).to eql ["can't be blank"]
        expect(subject.errors[:name]).to eql ["can't be blank"]
        subject = described_class.from_hash aggregate_id: 'l-1', name: 'category-1'
        expect(subject.valid?).to be_truthy
        expect(subject.aggregate_id).to eql 'l-1'
        expect(subject.name).to eql 'category-1'
      end
    end
    
    describe described_class::RenameCategory do
      it "shold validate presence of aggregate_id, category_id and name" do
        subject = described_class.from_hash Hash.new
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:aggregate_id]).to eql ["can't be blank"]
        expect(subject.errors[:category_id]).to eql ["can't be blank"]
        expect(subject.errors[:name]).to eql ["can't be blank"]
        subject = described_class.from_hash aggregate_id: 'l-1', category_id: 'c-1', name: 'category-1'
        expect(subject.valid?).to be_truthy
        expect(subject.aggregate_id).to eql 'l-1'
        expect(subject.category_id).to eql 'c-1'
        expect(subject.name).to eql 'category-1'
      end
    end
    
    describe described_class::RemoveCategory do
      it "shold validate presence of aggregate_id, category_id" do
        subject = described_class.from_hash Hash.new
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:aggregate_id]).to eql ["can't be blank"]
        expect(subject.errors[:category_id]).to eql ["can't be blank"]
        subject = described_class.from_hash aggregate_id: 'l-1', category_id: 'c-1'
        expect(subject.valid?).to be_truthy
        expect(subject.aggregate_id).to eql 'l-1'
        expect(subject.category_id).to eql 'c-1'
      end
    end
    
    describe described_class::SetAccountCategory do
      it "shold validate presence of aggregate_id, account, category_id" do
        subject = described_class.from_hash Hash.new
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:aggregate_id]).to eql ["can't be blank"]
        expect(subject.errors[:account_id]).to eql ["can't be blank"]
        expect(subject.errors[:category_id]).to eql ["can't be blank"]
        subject = described_class.from_hash aggregate_id: 'l-1', account_id: 'a-1', category_id: 'c-1'
        expect(subject.valid?).to be_truthy
        expect(subject.aggregate_id).to eql 'l-1'
        expect(subject.account_id).to eql 'a-1'
        expect(subject.category_id).to eql 'c-1'
      end
    end
  end
  
  describe described_class::PendingTransactionCommands do
    shared_examples :aliased_transaction_id do
      it 'should alias transaction_id to aggregate_id' do
        subject = described_class.new 'aggregate-223991'
        expect(subject.transaction_id).to eql 'aggregate-223991'
      end
    end
    
    shared_examples :required_aggregate_id do
      it 'should validate presence of aggregate_id' do
        subject = described_class.from_hash Hash.new
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:aggregate_id]).to eql ["can't be blank"]
      end
    end
    
    describe described_class::ReportPendingTransaction do
      it_behaves_like :aliased_transaction_id
      it_behaves_like :required_aggregate_id
    end
    
    describe described_class::AdjustPendingTransaction do
      it_behaves_like :aliased_transaction_id
      it_behaves_like :required_aggregate_id
    end
    
    describe described_class::ApprovePendingTransaction do
      it_behaves_like :aliased_transaction_id
      it_behaves_like :required_aggregate_id
    end
  end
end