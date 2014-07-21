module Loggable
  module ClassMethods
    def log
      @log ||= LogFactory.logger_for_class self
    end
  end
  
  module InstanceMethods
    def log
      self.class.log
    end
  end
  
  def self.included(receiver)
    receiver.send(:extend, ClassMethods)
    receiver.include InstanceMethods
  end
end