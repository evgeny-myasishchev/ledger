require 'rails_helper'

describe User do
  describe 'from_omniauth' do
    let(:email) { 'mail-4432@domain-544322.ua' }
    let(:auth) { double(:auth, info: double(:info, email: email))}

    it 'should find the user by email from auth.info' do
      User.create! email: 'fake-1@mail.com', password: 'fake-test-password'
      u = User.create! email: email, password: 'fake-test-password'
      expect(described_class.from_omniauth(auth)).to eql u
    end

    it 'should initialize new user object using auth data and return it' do
      created = described_class.from_omniauth(auth)
      expect(created.email).to eql(email)
      expect(created).not_to be_persisted
    end    
  end

  describe "get_device_secret" do
    subject { User.create! email: 'fake@mail.com', password: 'fake-password' }

    it 'should return existing device secret' do
      secret = DeviceSecret.create! user_id: subject.id, device_id: 'device-100', name: 'device-1', secret: 'secret-100'
      expect(subject.get_device_secret('device-100')).to eql secret
    end

    it 'should return null if no device secret available' do
      expect(subject.get_device_secret('secret-100')).to be_nil
    end
  end
  
  describe 'add_device_secret' do
    subject { User.create! email: 'fake@mail.com', password: 'fake-password' }
    
    it 'should add new device secret to the users device secrets and return it' do
      secret1 = subject.add_device_secret 'device-1', 'Device 1'
      secret2 = subject.add_device_secret 'device-2', 'Device 2'
      expect(subject.device_secrets.to_a).to eql [secret1, secret2]
      expect(secret1).to be_persisted
      expect(secret1.secret).not_to be_nil
      expect(secret2).to be_persisted
      expect(secret2.secret).not_to be_nil
    end
  end

  describe 'reset_device_secret' do
    subject { User.create! email: 'fake@mail.com', password: 'fake-password' }
    let(:device_secret) { subject.add_device_secret 'device-1', 'Device 1' }
    it 'should regenerate net secret key' do
      initial_secret = device_secret.secret
      subject.reset_device_secret device_secret.id
      device_secret.reload
      expect(device_secret.secret).not_to eql initial_secret
    end

    it 'should raise error if removing not existing device secret' do
      device_secret.delete
      expect { subject.reset_device_secret(device_secret.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'remove_device_secret' do
    subject { User.create! email: 'fake@mail.com', password: 'fake-password' }
    it 'should remove existing device secret by id' do
      secret1 = subject.add_device_secret 'device-1', 'Device 1'
      subject.remove_device_secret secret1.id
      expect(DeviceSecret).not_to exist(secret1.id)
    end

    it 'should raise error if removing not existing device secret' do
      expect { subject.remove_device_secret(100332) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
