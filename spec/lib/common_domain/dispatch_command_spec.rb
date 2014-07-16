require 'rails_helper'

RSpec.describe CommonDomain::DispatchCommand, type: :model do
  let(:dispatch_middleware) { double(:dispatch_middleware) }
  let(:domain_context) { double(:domain_context, command_dispatch_middleware: dispatch_middleware) }
  let(:dispatch_context) { double(:dispatch_context) }
  let(:command) { double(:command) }
  
  class SubjectClass
    include CommonDomain::DispatchCommand
    attr_reader :domain_context, :dispatch_context
    
    def initialize(domain_context, dispatch_context)
      @domain_context, @dispatch_context = domain_context, dispatch_context
    end
  end
  
  subject { SubjectClass.new(domain_context, dispatch_context) }
  
  describe "dispatch_command" do
    it "should use dispatch_middleware to send the command" do
      expect(dispatch_middleware).to receive(:call).with(command, dispatch_context)
      subject.dispatch_command command
    end
  end
  
  describe "dispatch_context" do
    subject { 
      Class.new do
        include CommonDomain::DispatchCommand
        attr_reader :env
        def initialize env
          @env = env
        end
      end.new double(:env)
    }
    
    it "should be an instance of DispatchContext" do
      expect(subject.dispatch_context).to be_an_instance_of CommonDomain::DispatchCommand::DispatchContext
    end
    
    it "should be initialized with controller" do
      expect(subject.dispatch_context.controller).to be subject
    end
    
    it "should be memoised" do
      expect(subject.dispatch_context).to be subject.dispatch_context
    end
  end
  
  describe "domain_context" do
    subject { Class.new do
      include CommonDomain::DispatchCommand
    end.new}
    it "should be taken from the rails application" do
      expect(Rails.application).to receive(:domain_context).and_return(domain_context)
      expect(subject.domain_context).to be domain_context
    end
  end
end