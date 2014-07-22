require 'rails_helper'

describe Application::Commands do
  describe Application::Commands::IncomeExpenceCommandFactory do
    let(:described_class) {
      Class.new(CommonDomain::Command) do
        include Application::Commands::IncomeExpenceCommandFactory
        attr_reader :ammount, :date, :tag_ids, :comment
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
          ammount: '22110',
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
    
      it "should assign command attributes" do
        params[:command][:tag_ids] = ['t-1', 't-2']
        params[:command][:comment] = 'Command comment 201120'
        expect(subject.ammount).to eql '22110'
        expect(subject.date).not_to be_nil
        expect(subject.tag_ids).to eql ['t-1', 't-2']
        expect(subject.comment).to eql 'Command comment 201120'
      end
    
      it "should parse the date from ISO 8601 format" do
        expect(subject.date).to eql date
      end
    
      it "should fail if ammount is not specified" do
        params[:command][:ammount] = nil
        expect{subject}.to raise_error ArgumentError, 'ammount is missing'
      end
    
      it "should fail if date is not specified" do
        params[:command][:date] = nil
        expect{subject}.to raise_error ArgumentError, 'date is missing'
      end
    end
  end
  
  describe described_class::TransferCommandFactory do
    let(:described_class) {
      Class.new(CommonDomain::Command) do
        include Application::Commands::TransferCommandFactory
        attr_reader :receiving_account_id, :ammount_sent, :ammount_received, :date, :tag_ids, :comment
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
          receiving_account_id: 'receiving-2291',
          ammount_sent: '22110',
          ammount_received: '100110',
          date: date.iso8601
        }
      end
    
      subject { described_class.build_from_params params }
    
      it "should assign command attributes" do
        params[:command][:tag_ids] = ['t-1', 't-2']
        params[:command][:comment] = 'Command comment 201120'
        expect(subject.aggregate_id).to eql 'sending-993'
        expect(subject.receiving_account_id).to eql 'receiving-2291'
        expect(subject.ammount_sent).to eql '22110'
        expect(subject.ammount_received).to eql '100110'
        expect(subject.date).to eql date
        expect(subject.tag_ids).to eql ['t-1', 't-2']
        expect(subject.comment).to eql 'Command comment 201120'
      end
      
      it "should fail if the account_id is not specified" do
        params[:account_id] = nil
        expect{subject}.to raise_error ArgumentError, 'account_id is missing'
      end
      
      it "should fail if the receiving_account_id is not specified" do
        params[:command][:receiving_account_id] = nil
        expect{subject}.to raise_error ArgumentError, 'receiving_account_id is missing'
      end
    
      it "should fail if ammount_sent is not specified" do
        params[:command][:ammount_sent] = nil
        expect{subject}.to raise_error ArgumentError, 'ammount_sent is missing'
      end
    
      it "should fail if ammount_received is not specified" do
        params[:command][:ammount_received] = nil
        expect{subject}.to raise_error ArgumentError, 'ammount_received is missing'
      end
    
      it "should fail if date is not specified" do
        params[:command][:date] = nil
        expect{subject}.to raise_error ArgumentError, 'date is missing'
      end
    end
  end
  
  describe described_class::AccountCommands::ReportIncome do
    it "should include the IncomeExpenceCommandFactory" do
      expect(subject).to be_a(Application::Commands::IncomeExpenceCommandFactory)
    end
  end
  
  describe described_class::AccountCommands::ReportExpence do
    it "should include the IncomeExpenceCommandFactory" do
      expect(subject).to be_a(Application::Commands::IncomeExpenceCommandFactory)
    end
  end
  
  describe described_class::AccountCommands::ReportRefund do
    it "should include the IncomeExpenceCommandFactory" do
      expect(subject).to be_a(Application::Commands::IncomeExpenceCommandFactory)
    end
  end
    
  describe described_class::AccountCommands::ReportTransfer do
    it "should include the TransferCommandFactory" do
      expect(subject).to be_a(Application::Commands::TransferCommandFactory)
    end
  end
end