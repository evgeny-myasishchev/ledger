class CommonDomain::DispatchCommand::DispatchContext
  def user_id
    raise 'Not implemented'
  end
    
  def remote_ip
    raise 'Not implemented'
  end
  
  class StaticDispatchContext < self
    attr_reader :user_id, :remote_ip
    
    def initialize user_id, remote_ip
      @user_id = user_id
      @remote_ip = remote_ip
    end
  end
  
  class ControllerDispatchContext < self
    def initialize controller, options = {}
      @controller = controller
      @options = {
        user_id: :user_id
      }.merge! options
    end
    
    def remote_ip
      @controller.request.remote_ip
    end
    
    def user_id
      user_id_option = @options[:user_id]
      if user_id_option.respond_to? :call
        user_id_option.call(@controller)
      else
        @controller.session[user_id_option]
      end
    end
  end
end