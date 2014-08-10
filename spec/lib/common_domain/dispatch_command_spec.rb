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
        
        def self.build_dispatch_context(target)
        end
      end.new
    }
    
    it "should be built with factory" do
      dispatch_context = double(:dispatch_context)
      expect(subject.class).to receive(:build_dispatch_context).with(subject).and_return dispatch_context
      expect(subject.dispatch_context).to be dispatch_context
    end
    
    it "should be memoised" do
      allow(subject.class).to receive(:build_dispatch_context) { double(:dispatch_context) }
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
  
  describe "dispatch_with_controller_context" do
    subject { 
      Class.new do
        include CommonDomain::DispatchCommand
        dispatch_with_controller_context user_id: 'user-id-option'
      end.new
    }
    
    it "should configure controller context to be used" do
      controller_context = double(:controller_context)
      expect(CommonDomain::DispatchCommand::DispatchContext::ControllerDispatchContext).to receive(:new) do |controller, options|
        expect(controller).to be subject
        expect(options).to eql user_id: 'user-id-option'
        controller_context
      end
      expect(subject.dispatch_context).to be controller_context
    end
  end
end