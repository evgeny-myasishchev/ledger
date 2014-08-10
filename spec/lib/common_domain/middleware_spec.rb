require 'rails_helper'

RSpec.shared_context 'dispatch command middleware shared stuff' do
  let(:the_next) { double(:next, call: nil) }
  let(:context) { double(:context) }
  let(:command) { CommonDomain::Command.new 'aggregate-100' }
  subject { described_class.new the_next }
end

RSpec.describe CommonDomain::DispatchCommand::Middleware::Base do
  include_context 'dispatch command middleware shared stuff'
  describe "call" do
    it "should call the next with command and context" do
      subject.call command, context
      expect(the_next).to have_received(:call).with(command, context)
    end
    
    it "should return the result of the next" do
      allow(the_next).to receive(:call) { 'result' }
      expect(subject.call(command, context)).to eql 'result'
    end
  end
end

RSpec.describe CommonDomain::DispatchCommand::Middleware::Stack do
  include_context 'dispatch command middleware shared stuff'
  
  describe "initialize" do
    it "should yield the block if provided with self" do
      the_s = nil
      subject = described_class.new(the_next) do |s|
        the_s = s
      end
      expect(the_s).to be subject
    end
  end
  
  describe "with" do
    it "should instantiate a new middleware with the original next and args and replace the next with it" do
      new_next = double(:new_next)
      new_next_class = double(:new_next_class)
      expect(new_next_class).to receive(:new).with(the_next, 'arg-1', 'arg-2').and_return(new_next)
      subject.with new_next_class, 'arg-1', 'arg-2'
      expect(subject.next).to be new_next
    end
  end
end

RSpec.describe CommonDomain::DispatchCommand::Middleware::Dispatch do
  include_context 'dispatch command middleware shared stuff'
  let(:dispatcher) { double(:dispatcher) }
  subject { described_class.new dispatcher }
  
  describe "call" do
    it "should use the dispatcher to dispatch the command" do
      expect(dispatcher).to receive(:dispatch).with(command).and_return('the result')
      expect(subject.call(command, context)).to eql 'the result'
    end
  end
end

RSpec.describe CommonDomain::DispatchCommand::Middleware::ValidateCommands do
  include_context 'dispatch command middleware shared stuff'
  describe "call" do
    describe "validatable command" do
      let(:command) { double(:command, valid?: true) }
      
      it "should call next if command is valid" do
        expect(the_next).to receive(:call).with(command, context)
        subject.call command, context
      end
      
      it "should raise CommandInvalidError if the command is invalid" do
        expect(command).to receive(:valid?) { false }
        expect { subject.call command, context }.
          to raise_error CommonDomain::DispatchCommand::CommandValidationFailedError, "Command validation failed: #{command}"
      end
      
      it "should raise CommandInvalidError with full error messages if supported" do
        expect(command).to receive(:valid?) { false }
        expect(command).to receive(:errors) { double(:errors, full_messages: ['error1', 'error2']) }
        expect { subject.call command, context }.
          to raise_error CommonDomain::DispatchCommand::CommandValidationFailedError, "Command validation failed: #{['error1', 'error2']}"
      end
    end
  end
end

RSpec.describe CommonDomain::DispatchCommand::Middleware::TrackUser do
  include_context 'dispatch command middleware shared stuff'

  before(:each) do
    allow(context).to receive(:user_id) { 'user-332211' }
    allow(context).to receive(:remote_ip) { '11.22.33.44' }
  end
  
  describe "call" do
    it "should assign the ip address" do
      subject.call(command, context)
      expect(command.headers[:ip_address]).to eql '11.22.33.44'
    end
    
    it "should assign user_id" do
      subject.call(command, context)
      expect(command.headers[:user_id]).to eql 'user-332211'
    end
    
    it "should call the next" do
      expect(the_next).to receive(:call).with(command, context) { 'result-7692' }
      expect(subject.call(command, context)).to eql 'result-7692'
    end
  end
end