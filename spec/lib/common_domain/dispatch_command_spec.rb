require 'rails_helper'

RSpec.describe CommonDomain::DispatchCommand, type: :model do
  let(:command_dispatch_app) { instance_double(CommonDomain::DispatchCommand::Middleware::Base) }
  let(:dispatch_context) { instance_double(CommonDomain::DispatchCommand::DispatchContext) }
  let(:command) { double(:command) }
  
  class SubjectClass
    include CommonDomain::DispatchCommand
    attr_reader :command_dispatch_app
    
    def initialize(command_dispatch_app, dispatch_context)
      @command_dispatch_app, @dispatch_context = command_dispatch_app, dispatch_context
    end
  end
  
  subject { SubjectClass.new(command_dispatch_app, dispatch_context) }
  
  before do
    allow(Rails.application).to receive(:command_dispatch_app) { command_dispatch_app }
  end
  
  describe "dispatch_command" do
    it "should use Rails.application.command_dispatch_app to send the command" do
      expect(Rails.application.command_dispatch_app).to receive(:call).with(command, dispatch_context)
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
      expect(subject.class).to receive(:build_dispatch_context).with(subject).and_return dispatch_context
      expect(subject.dispatch_context).to be dispatch_context
    end
    
    it "should be memoised" do
      allow(subject.class).to receive(:build_dispatch_context) { double(:dispatch_context) }
      expect(subject.dispatch_context).to be subject.dispatch_context
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
      controller_context = double(CommonDomain::DispatchCommand::DispatchContext::ControllerDispatchContext)
      expect(CommonDomain::DispatchCommand::DispatchContext::ControllerDispatchContext).to receive(:new) do |controller, options|
        expect(controller).to be subject
        expect(options).to eql user_id: 'user-id-option'
        controller_context
      end
      expect(subject.dispatch_context).to be controller_context
    end
  end
end