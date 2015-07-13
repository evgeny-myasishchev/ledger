require 'rails_helper'

RSpec.describe Api::DevicesController, type: :controller do
  describe "routes", :type => :routing do
    it "routes POST register" do
      expect({post: 'api/devices/register'}).to route_to controller: 'api/devices', action: 'register'
    end
  end

  include AuthenticationHelper
  authenticate_user

  describe 'POST register' do
    let(:secret) { DeviceSecret.new(secret: 'secret-100') }
    it 'should get device secret of previously registered device' do
      expect(controller.current_user).to receive(:get_device_secret).with('device-100') { secret }
      post :register, device_id: 'device-100', format: :json
      expect(response.status).to eql 200
      expect(response.body).to eql({secret: 'secret-100'}.to_json)
    end

    it 'should add and return new secret for new device' do
      expect(controller.current_user).to receive(:get_device_secret).with('device-100') { nil }
      expect(controller.current_user).to receive(:add_device_secret).with('device-100', 'Device 100') { secret }
      post :register, device_id: 'device-100', name: 'Device 100', format: :json
      expect(response.status).to eql 200
      expect(response.body).to eql({secret: 'secret-100'}.to_json)      
    end
  end
end
