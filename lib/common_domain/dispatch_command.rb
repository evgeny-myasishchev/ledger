module CommonDomain
  module DispatchCommand
    def dispatch_command command
      domain_context.dispatch_middleware.call(command, dispatch_context)
    end
    
    def dispatch_context
      @dispatch_context ||= DispatchContext.new self
    end
    
    def domain_context
      Rails.application.domain_context
    end
  end
end