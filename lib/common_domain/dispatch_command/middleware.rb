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
    
    # This middleware is used to assign user related info into the command headers.
    # Following headers assigned: 
    # * user_id - Id of the user that issues the command
    # * ip_address - Ip address of the user
    #
    # Sample usage:
    # command_middleware do |m|
    #   m.with CommonDomain::Middleware::TrackUser, :user_id => :user_id
    # end
    #
    # Initialization arguments are:
    # * user_id - session key name to obtain user_id
    class TrackUser < Base
      def initialize(the_next, options)
        @options = {
          user_id: nil
        }.merge! options
        raise "Please specify user_id option." if @options[:user_id].nil?
        super the_next
      end

      def call(command, context)
        user_id_option = @options[:user_id]
        if user_id_option.respond_to? :call
          command.headers[:user_id] = user_id_option.call(context)
        else
          command.headers[:user_id] = context.controller.session[user_id_option]
        end
        command.headers[:ip_address] = context.controller.request.remote_ip
        super(command, context)
      end
    end
  end
end