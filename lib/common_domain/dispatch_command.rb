module CommonDomain
  
  # Include the module to your controller and feel free to dispatch commands using the dispatch_command method.
  module DispatchCommand
    class CommandValidationFailedError < StandardError
    end
    
    def dispatch_command command
      domain_context.command_dispatch_middleware.call(command, dispatch_context)
    end
    
    def dispatch_context
      @dispatch_context ||= DispatchContext.new self
    end
    
    def domain_context
      Rails.application.domain_context
    end
  end
end