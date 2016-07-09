require 'rails_helper'

describe AccessToken do
  let(:rsa_private) { OpenSSL::PKey::RSA.generate 2048 }
  let(:rsa_public) { rsa_private.public_key }

  let(:payload) do
    {
      'aud' => FFaker::Internet.domain_name
    }
  end

  describe 'ensure_audience!' do
    it 'should raise error if audience mismatch' do
    end

    it 'should return self if audience match' do
    end
  end

  describe 'extract' do
    let(:raw_jwt_token) { JWT.encode payload, rsa_private, 'RS256' }

    let(:valid_cert) do
      cert = OpenSSL::X509::Certificate.new
      cert.public_key = rsa_public
      cert
    end

    let(:invalid_cert) do
      cert = OpenSSL::X509::Certificate.new
      cert.public_key = OpenSSL::PKey::RSA.generate(2048).public_key
      cert
    end

    it 'should decode provided raw JWT data and create new instance' do
      access_token = described_class.extract raw_jwt_token, [valid_cert]
      expect(access_token.payload).to eql(payload)
    end

    it 'should support multiple certificates when decoding' do
      access_token = described_class.extract raw_jwt_token, [invalid_cert, valid_cert]
      expect(access_token.payload).to eql(payload)
    end

    it 'should raise error if certificates does not match' do
      expect(lambda do
        described_class.extract raw_jwt_token, [invalid_cert]
      end).to raise_error(JWT::VerificationError)
    end
  end
end
