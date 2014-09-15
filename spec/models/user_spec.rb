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

    it 'should create a new using auth data and return it' do      
      created = described_class.from_omniauth(auth)
      expect(created.email).to eql(email)
      expect(described_class.find(created.id)).to eql created
    end    
  end
end
