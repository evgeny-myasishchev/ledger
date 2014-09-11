module Application::CommandFactories
  
  module IncomeExpenceCommandFactory
    extend ActiveSupport::Concern
    module ClassMethods
      def build_from_params params
        account_id = params[:account_id]
        amount = params[:command][:amount]
        date = params[:command][:date]
        raise ArgumentError.new 'account_id is missing' if account_id.blank?
        raise ArgumentError.new 'amount is missing' if amount.blank?
        raise ArgumentError.new 'date is missing' if date.blank?
        new account_id, amount: amount, date: DateTime.iso8601(date), tag_ids: params[:command][:tag_ids], comment: params[:command][:comment]
      end
    end
  end
  
  module TransferCommandFactory
    extend ActiveSupport::Concern
    module ClassMethods
      def build_from_params params
        account_id = params[:account_id]
        receiving_account_id = params[:command][:receiving_account_id]
        amount_sent = params[:command][:amount_sent]
        amount_received = params[:command][:amount_received]
        date = params[:command][:date]
        raise ArgumentError.new 'account_id is missing' if account_id.blank?
        raise ArgumentError.new 'receiving_account_id is missing' if receiving_account_id.blank?
        raise ArgumentError.new 'amount_sent is missing' if amount_sent.blank?
        raise ArgumentError.new 'amount_received is missing' if amount_received.blank?
        raise ArgumentError.new 'date is missing' if date.blank?
        new account_id, receiving_account_id: receiving_account_id,
          amount_sent: amount_sent,
          amount_received: amount_received,
          date: DateTime.iso8601(date),
          tag_ids: params[:command][:tag_ids],
          comment: params[:command][:comment]
      end
    end
  end
end