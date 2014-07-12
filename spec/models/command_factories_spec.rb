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
end