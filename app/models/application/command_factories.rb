module Application::CommandFactories
  
  module IncomeExpenceCommandFactory
    extend ActiveSupport::Concern
    module ClassMethods
      def build_from_params params
        account_id = params[:account_id]
        transaction_id = params[:command][:transaction_id]
        amount = params[:command][:amount]
        date = params[:command][:date]
        
        raise ArgumentError.new 'account_id is missing' if account_id.blank?
        raise ArgumentError.new 'transaction_id is missing' if transaction_id.blank?
        raise ArgumentError.new 'amount is missing' if amount.blank?
        raise ArgumentError.new 'date is missing' if date.blank?
        
        new account_id, transaction_id: transaction_id, amount: amount, date: DateTime.iso8601(date), tag_ids: params[:command][:tag_ids], comment: params[:command][:comment]
      end
    end
  end
  
  module TransferCommandFactory
    extend ActiveSupport::Concern
    module ClassMethods
      def build_from_params params
        account_id = params[:account_id]
        sending_transaction_id = params[:command][:sending_transaction_id]
        receiving_transaction_id = params[:command][:receiving_transaction_id]
        receiving_account_id = params[:command][:receiving_account_id]
        amount_sent = params[:command][:amount_sent]
        amount_received = params[:command][:amount_received]
        date = params[:command][:date]
        
        raise ArgumentError.new 'account_id is missing' if account_id.blank?
        raise ArgumentError.new 'sending_transaction_id is missing' if sending_transaction_id.blank?
        raise ArgumentError.new 'receiving_transaction_id is missing' if receiving_transaction_id.blank?
        raise ArgumentError.new 'receiving_account_id is missing' if receiving_account_id.blank?
        raise ArgumentError.new 'amount_sent is missing' if amount_sent.blank?
        raise ArgumentError.new 'amount_received is missing' if amount_received.blank?
        raise ArgumentError.new 'date is missing' if date.blank?
        new account_id, 
          sending_transaction_id: sending_transaction_id, 
          receiving_transaction_id: receiving_transaction_id, 
          receiving_account_id: receiving_account_id,
          amount_sent: amount_sent,
          amount_received: amount_received,
          date: DateTime.iso8601(date),
          tag_ids: params[:command][:tag_ids],
          comment: params[:command][:comment]
      end
    end
  end
end