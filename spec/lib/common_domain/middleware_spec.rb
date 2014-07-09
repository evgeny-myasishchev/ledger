require 'rails_helper'

RSpec.shared_context 'dispatch command middleware shared stuff' do
  let(:the_next) { double(:next, call: nil) }
  let(:context) { double(:context) }
  let(:command) { CommonDomain::Command.new 'aggregate-100' }
  subject { described_class.new the_next}
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

RSpec.describe CommonDomain::DispatchCommand::Middleware::TrackUser do
  include_context 'dispatch command middleware shared stuff'
  let(:request) { double(:request, remote_ip: '11.22.33.44')}
  let(:session) { Hash.new }
  let(:controller) { double(:controller, request: request, session: session) }
  before(:each) do
    allow(context).to receive(:controller) { controller }
  end
  
  shared_examples 'TrackUser.call' do
    it "should assign the ip address" do
      subject.call(command, context)
      expect(command.headers[:ip_address]).to eql '11.22.33.44'
    end
    
    it "should call the next" do
      expect(the_next).to receive(:call).with(command, context) { 'result-7692' }
      expect(subject.call(command, context)).to eql 'result-7692'
    end
  end
  
  describe "call" do
    describe "with user_id as a session_key option" do
      it_behaves_like 'TrackUser.call'
      subject { described_class.new the_next, user_id: 'user-id-session-key' }
      before(:each) do
        session['user-id-session-key'] = 'user-332211'
      end
      
      it "should take the user_id from the session by key and assign it as a user_id header" do
        subject.call(command, context)
        expect(command.headers[:user_id]).to eql 'user-332211'
      end
    end
    
    describe "with user_id as a proc" do
      it_behaves_like 'TrackUser.call'
      subject { described_class.new the_next, user_id: lambda { |c|  
        expect(c).to be context
        'user-332211-from-proc'
      } }
      
      it "should take the user_id from the session by key and assign it as a user_id header" do
        subject.call(command, context)
        expect(command.headers[:user_id]).to eql 'user-332211-from-proc'
      end
    end
  end
end