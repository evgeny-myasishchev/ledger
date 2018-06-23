require 'rails_helper'

describe AccessToken do
  KEY_SIZE = 512 # Using smaller keys as they work faster
  let(:rsa_private) { generate_rsa_private }
  let(:rsa_public) { rsa_private.public_key }
  let(:subject) { described_class.new payload }
  let(:header) do
    {
      'kid' => random_string('kid')
    }
  end
  let(:payload) do
    {
      'aud' => FFaker::Internet.domain_name,
      'email' => FFaker::Internet.email
    }
  end

  it 'should provide email accessor' do
    expect(described_class.new(payload).email).to eql(payload['email'])
  end

  describe 'validate_audience!' do
    it 'should raise error if audience mismatch' do
      invalid_aud = random_string('VALID-AUD')
      expect(-> { subject.validate_audience!(invalid_aud) })
        .to raise_error AccessToken::TokenError, "Invalid audience: #{payload['aud']}"
    end

    it 'validate audience as an array' do
      expect(subject.validate_audience!(['invalid aud 1', 'invalid aud 2', payload['aud']])).to be(subject)
    end

    it 'validate audience as a set' do
      expect(subject.validate_audience!(Set.new(['invalid aud 1', 'invalid aud 2', payload['aud']]))).to be(subject)
      expect(-> { subject.validate_audience!(Set.new(['invalid aud 1', 'invalid aud 2'])) })
        .to raise_error AccessToken::TokenError, "Invalid audience: #{payload['aud']}"
    end

    it 'should return self if audience match' do
      expect(subject.validate_audience!(payload['aud'])).to be(subject)
    end
  end

  describe 'extract' do
    let(:raw_jwt_token) { JWT.encode payload, rsa_private, 'RS256', header }

    let(:valid_cert) do
      create_x509_cert public_key: rsa_public
    end

    let(:invalid_cert) do
      create_x509_cert
    end

    before(:each) do
      allow(AccessToken::Certificates).to receive(:get_certificate).with(payload, hash_including(header)) { valid_cert }
    end

    it 'should decode provided raw JWT data and create new instance' do
      access_token = described_class.extract raw_jwt_token
      expect(access_token.payload).to eql(payload)
    end

    it 'should raise error if certificates does not match' do
      allow(AccessToken::Certificates).to receive(:get_certificate) { invalid_cert }
      expect(lambda do
        described_class.extract raw_jwt_token
      end).to raise_error(AccessToken::TokenError)
    end
  end
end
