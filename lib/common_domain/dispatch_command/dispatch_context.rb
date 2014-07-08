module CommonDomain::DispatchCommand
  class DispatchContext
    attr_reader :env, :controller
    
    def initialize controller
      @controller = controller
      @env = controller.env
    end
  end
end