module CommonDomain::DispatchCommand
  module Middleware
    
    # The base class for all middlewares
    class Base
      attr_reader :next
      def initialize(the_next)
        @next = the_next
      end
      
      def call(command, context)
        @next.call(command, context)
      end
    end
    
    class Stack < Base
      def initialize(the_next, &block)
        super(the_next)
        yield(self) if block_given?
      end
      
      #Append a middleware to the top of the middleware stack. Last added middleware called first.
      #Each middleware is a class reference. The class should have an initializer method with at least one argument.
      #The argument is a next middleware instance. It should be explicitly called in "call" method. 
      #All the middlewares job is performed in "call" method. The method accepts two arguments:
      # * command - command instance
      # * context - command context (see CommandMiddleware::Context for more details.)
      #Sample:
      # class LogCommands
      #   def initialize(app)
      #     @app = app
      #   end
      #   
      #   def call(command, context)
      #     puts "Executing command: #{command}"
      #     @app.call(command, context)
      #   end
      # end
      def with middleware_class, *args
        @next = middleware_class.new @next, *args
      end
    end
    
    # Final middleware the does the actual dispatch
    class Dispatch < Base
      def initialize(dispatcher)
        @dispatcher = dispatcher
      end
      
      def call(command, context)
        @dispatcher.dispatch(command)
      end
    end
    
    class ValidateCommands < Base
      def call(command, context)
        begin
          unless command.valid?
            details = command.respond_to?(:errors) ? command.errors.full_messages : command
            raise CommonDomain::DispatchCommand::CommandValidationFailedError.new "Command validation failed: #{details}"
          end
        end if command.respond_to?(:valid?)
        super(command, context)
      end
    end
    
    # This middleware is used to assign user related info into the command headers.
    # Following headers assigned: 
    # * user_id - Id of the user that issues the command
    # * ip_address - Ip address of the user
    # 
    # The data is taken from dispatch_context
    #
    # Sample usage:
    # command_middleware do |m|
    #   m.with CommonDomain::Middleware::TrackUser
    # end
    class TrackUser < Base
      def call(command, context)
        command.headers[:user_id] = context.user_id
        command.headers[:ip_address] = context.remote_ip
        super(command, context)
      end
    end
  end
end