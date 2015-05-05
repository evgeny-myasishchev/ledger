require 'spec_helper'

module ApplicationCommandsRegularCommandsSpec
  include Application::Commands::AccountCommands
  
  describe Application::Commands do
    describe 'regular transactions' do
      shared_examples 'regular transaction' do
        let(:params) { Hash.new }
        let(:date) { 
          d = (DateTime.now - 100)
          d = d.iso8601
          DateTime.iso8601 d
        }
        before(:each) do
          params.merge!(account_id: 'account-993',
            transaction_id: 'transaction-100',
            amount: '22110',
            comment: 'Command comment 201120',
            tag_ids: ['t-1', 't-2'],
            date: date.iso8601)
        end
    
        subject { described_class.from_hash params }
    
        it "should assign command attributes" do
          expect(subject.account_id).to eql 'account-993'
          expect(subject.amount).to eql '22110'
          expect(subject.date).not_to be_nil
          expect(subject.tag_ids).to eql ['t-1', 't-2']
          expect(subject.comment).to eql 'Command comment 201120'
        end
    
        it "should parse the date from ISO 8601 format" do
          expect(subject.date).to eql date
        end
        
        it 'should accept date as an object' do
          params[:date] = date
          subject = described_class.from_hash params
          expect(subject.date).to be date
        end
    
        it 'should validate presence of required attributes' do
          subject = described_class.new account_id: '', transaction_id: '', amount: '', comment: '', tag_ids: nil, date: nil
          expect(subject.valid?).to be_falsey
          expect(subject.errors[:account_id]).to eql ["can't be blank"]
          expect(subject.errors[:transaction_id]).to eql ["can't be blank"]
          expect(subject.errors[:amount]).to eql ["can't be blank"]
          expect(subject.errors[:date]).to eql ["can't be blank"]
        end
      end
      
      describe ReportIncome do
        it_should_behave_like 'regular transaction'
      end

      describe ReportExpense do
        it_should_behave_like 'regular transaction'
      end
      
      describe ReportRefund do
        it_should_behave_like 'regular transaction'
      end
    end
  end
end