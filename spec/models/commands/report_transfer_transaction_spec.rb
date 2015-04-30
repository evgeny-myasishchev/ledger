require 'rails_helper'

describe Application::Commands do
  describe Application::Commands::AccountCommands::ReportTransfer do
    describe "build_from_params" do
      let(:params) { Hash.new }
      let(:date) { 
        d = (DateTime.now - 100)
        d = d.iso8601
        DateTime.iso8601 d
      }
      before(:each) do
        params.merge!(aggregate_id: 'sending-993',
          sending_transaction_id: 'transaction-101',
          receiving_transaction_id: 'transaction-102',
          receiving_account_id: 'receiving-2291',
          amount_sent: '22110',
          amount_received: '100110',
          tag_ids: ['t-1', 't-2'],
          comment: 'Command comment 201120',
          date: date.iso8601)
      end
    
      subject { described_class.from_hash params }
    
      it "should assign command attributes" do
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
      
      it 'should validate presence of required attributes' do
        params.merge!(aggregate_id: nil,
          sending_transaction_id: nil,
          receiving_transaction_id: nil,
          receiving_account_id: nil,
          amount_sent: nil,
          amount_received: nil,
          date: nil)
        subject = described_class.new params
        expect(subject.valid?).to be_falsey
        expect(subject.errors[:aggregate_id]).to eql ["can't be blank"]
        expect(subject.errors[:sending_transaction_id]).to eql ["can't be blank"]
        expect(subject.errors[:receiving_transaction_id]).to eql ["can't be blank"]
        expect(subject.errors[:amount_sent]).to eql ["can't be blank"]
        expect(subject.errors[:amount_received]).to eql ["can't be blank"]
        expect(subject.errors[:date]).to eql ["can't be blank"]
      end
    end
  end
end