class DomainContext < CommonDomain::DomainContext
  include CommonDomain
  
  attr_reader :command_dispatcher
  
  def initialize(&block)
    yield(self)
  end
  
  def with_event_store
    bootstrap_event_store do |with|
      with.log4r_logging
    end
  end
  
  def with_command_handlers
    @command_dispatcher = CommandDispatcher.new do |dispatcher|
      # dispatcher.register Sample::CommandHandlers::AccountHandlers.new(@repository)
    end
  end
  
  def with_services
    
  end
  
  def with_read_models
    bootstrap_read_models do |read_models|
      # read_models.register :accounts, Sample::ReadModels::AccountsReadModel.new
    end
  end
end