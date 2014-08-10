module CommonDomain
  
  # Include the module to your controller and feel free to dispatch commands using the dispatch_command method.
  module DispatchCommand
    extend ActiveSupport::Concern
    
    class CommandValidationFailedError < StandardError
    end
    
    def dispatch_command command
      domain_context.command_dispatch_middleware.call(command, dispatch_context)
    end
    
    def dispatch_context
      @dispatch_context ||= self.class.build_dispatch_context(self)
    end
    
    def domain_context
      Rails.application.domain_context
    end
    
    module ClassMethods
      def dispatch_with_controller_context options
        @@controller_context_options = options
      end
      
      def build_dispatch_context(target)
        raise 'Can not build the dispatch context. No options provided.' unless @@controller_context_options
        DispatchContext::ControllerDispatchContext.new target, @@controller_context_options
      end
    end
  end
end