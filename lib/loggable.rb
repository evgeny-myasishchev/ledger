module Loggable
  module ClassMethods
    def logger
      @log ||= LogFactory.logger_for_class self
    end
  end
  
  module InstanceMethods
    def logger
      self.class.logger
    end
  end
  
  def self.included(receiver)
    receiver.send(:extend, ClassMethods)
    receiver.include InstanceMethods
  end
end