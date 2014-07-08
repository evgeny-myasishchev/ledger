module CommonDomain::DispatchCommand
  class DispatchContext
    attr_reader :env, :controller, :dispatcher
      
    def initialize controller, dispatcher
      @controller = controller
      @env        = controller.env
      @dispatcher = dispatcher
    end
  end
end
