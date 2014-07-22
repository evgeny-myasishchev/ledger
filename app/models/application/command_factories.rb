module Application::CommandFactories
  
  module IncomeExpenceCommandFactory
    extend ActiveSupport::Concern
    module ClassMethods
      def build_from_params params
        account_id = params[:account_id]
        ammount = params[:command][:ammount]
        date = params[:command][:date]
        raise ArgumentError.new 'account_id is missing' if account_id.blank?
        raise ArgumentError.new 'ammount is missing' if ammount.blank?
        raise ArgumentError.new 'date is missing' if date.blank?
        new account_id, ammount: ammount, date: DateTime.iso8601(date), tag_ids: params[:command][:tag_ids], comment: params[:command][:comment]
      end
    end
  end
  
  module TransferCommandFactory
    extend ActiveSupport::Concern
    module ClassMethods
      def build_from_params params
        account_id = params[:account_id]
        receiving_account_id = params[:command][:receiving_account_id]
        ammount_sent = params[:command][:ammount_sent]
        ammount_received = params[:command][:ammount_received]
        date = params[:command][:date]
        raise ArgumentError.new 'account_id is missing' if account_id.blank?
        raise ArgumentError.new 'receiving_account_id is missing' if receiving_account_id.blank?
        raise ArgumentError.new 'ammount_sent is missing' if ammount_sent.blank?
        raise ArgumentError.new 'ammount_received is missing' if ammount_received.blank?
        raise ArgumentError.new 'date is missing' if date.blank?
        new account_id, receiving_account_id: receiving_account_id,
          ammount_sent: ammount_sent,
          ammount_received: ammount_received,
          date: DateTime.iso8601(date),
          tag_ids: params[:command][:tag_ids],
          comment: params[:command][:comment]
      end
    end
  end
end