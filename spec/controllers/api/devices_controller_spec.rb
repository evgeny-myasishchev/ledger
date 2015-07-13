require 'rails_helper'

RSpec.describe Api::DevicesController, type: :controller do
  describe "routes", :type => :routing do
    it 'routes GET index' do
      expect({get: 'api/devices'}).to route_to controller: 'api/devices', action: 'index'
    end

    it 'routes DELETE destroy' do
      expect({delete: 'api/devices/100'}).to route_to controller: 'api/devices', action: 'destroy', id: '100'
    end

    it "routes POST register" do
      expect({post: 'api/devices/register'}).to route_to controller: 'api/devices', action: 'register'
    end
  end

  include AuthenticationHelper
  authenticate_user
  let(:current_user) { controller.current_user }

  describe 'GET index' do
    it 'should return all user secrets' do
      s1 = current_user.add_device_secret 'dev-1', 'Device 1'
      s2 = current_user.add_device_secret 'dev-2', 'Device 2'
      get :index, format: :json
      expect(response.status).to eql 200
      expect(response.body).to eql [s1, s2].to_json
    end
  end

  describe 'DELETE destroy' do
    it 'should delete user device secret' do
      expect(current_user).to receive(:remove_device_secret).with('100')
      post :destroy, id: '100'      
    end
  end

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
