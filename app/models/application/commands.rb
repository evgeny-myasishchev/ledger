module Application::Commands
  include CommonDomain::Command::DSL
  
  commands_group :AccountCommands do
    command :ReportIncome, :ammount, :date, :tag_ids, :comment
    command :ReportExpence, :ammount, :date, :tag_ids, :comment
  end
  
  AccountCommands::ReportIncome.class_eval do
    def self.build_from_params params
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