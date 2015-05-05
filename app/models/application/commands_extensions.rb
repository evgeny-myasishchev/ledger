module Application::CommandsExtensions
  module AdjustTransactionCommand
    extend ActiveSupport::Concern
    included do
      include ActiveModel::Validations
      validates :transaction_id, presence: true
    end
  end
  
  module ReportRegularTransactionCommand
    extend ActiveSupport::Concern
    included do
      include ActiveModel::Validations
      validates_presence_of :account_id, :transaction_id, :amount, :date
      def initialize_by_hash hash
        if (hash[:date] && !hash[:date].is_a?(Date))
          hash[:date] = DateTime.iso8601(hash[:date])
        end
        super
      end
    end
  end
  
  module ReportTransferTransactionCommand
    extend ActiveSupport::Concern
    included do
      include ActiveModel::Validations
      validates_presence_of :account_id, :sending_transaction_id, :receiving_transaction_id, :receiving_account_id, :amount_sent, :amount_received, :date
      
      def initialize_by_hash hash
        if (hash[:date] && !hash[:date].is_a?(Date))
          hash[:date] = DateTime.iso8601(hash[:date])
        end
        super
      end
    end
  end
  
  module PendingTransactionCommand
    extend ActiveSupport::Concern
    included do
      include ActiveModel::Validations
      validates :id, presence: true
    end
  end
end