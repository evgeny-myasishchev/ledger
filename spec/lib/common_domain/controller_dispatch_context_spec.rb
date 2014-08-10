require 'rails_helper'

RSpec.describe CommonDomain::DispatchCommand::DispatchContext::ControllerDispatchContext, type: :model do
  let(:request) { double(:request, remote_ip: '11.22.33.44')}
  let(:session) { Hash.new }
  let(:controller) { double(:controller, request: request, session: session) }
  
  it "should take remote_id from request" do
    subject = described_class.new controller
    expect(subject.remote_ip).to eql '11.22.33.44'
  end
  
  describe "user_id" do
    describe "with user_id as a session_key option" do
      subject { described_class.new controller, user_id: 'user-id-session-key' }
      it "should take the user_id from the session by key" do
        session['user-id-session-key'] = 'user-332211'
        expect(subject.user_id).to eql 'user-332211'
      end
    end
  
    describe "with user_id as a proc" do
      subject { described_class.new controller, user_id: lambda { |c|
        expect(c).to be controller
        'user-332211-from-proc'
      } }
    
      it "should use proc to resolve the user_id" do
        expect(subject.user_id).to eql 'user-332211-from-proc'
      end
    end
  end
end