require 'log4r/outputter/outputter'

class MailerLogOutputter < Log4r::Outputter
  attr_reader :from, :to, :subject

  def initialize(_name, hash={})
    super(_name, hash)
    @from, @to, @subject = hash[:from], hash[:to], hash[:subject]
  end
  
  class LogsMailer < ActionMailer::Base
    def log_data(from, to, subject, data)
      mail(from: from, to: to, subject: subject, body: data)
    end
  end
  
  def write(data)
    LogsMailer.log_data(from, to, subject, data).deliver_later
  end
end