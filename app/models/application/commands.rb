module Application::Commands
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
        raise "Not implemented"
      end
    end
  end
  
  include CommonDomain::Command::DSL
  commands_group :AccountCommands do
    command :ReportIncome, :ammount, :date, :tag_ids, :comment do
      include IncomeExpenceCommandFactory
    end
    command :ReportExpence, :ammount, :date, :tag_ids, :comment do
      include IncomeExpenceCommandFactory
    end
    command :ReportRefund, :ammount, :date, :tag_ids, :comment do
      include IncomeExpenceCommandFactory
    end
    command :ReportTransfer, :receiving_account_id, :ammount_sent, :ammount_received, :date, :tag_ids, :comment do
      include IncomeExpenceCommandFactory
    end
  end
end