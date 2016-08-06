require 'rails_helper'

describe AccessToken do
  KEY_SIZE = 512 # Using smaller keys as they work faster
  let(:rsa_private) { generate_rsa_private }
  let(:rsa_public) { rsa_private.public_key }
  let(:subject) { described_class.new payload }

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
      expect(-> { subject.validate_audience!('invlaid audience') })
        .to raise_error AccessToken::TokenError
    end

    it 'validate audience as an array' do
      expect(subject.validate_audience!(['invalid aud 1', 'invalid aud 2', payload['aud']])).to be(subject)
    end

    it 'validate audience as a set' do
      expect(subject.validate_audience!(Set.new(['invalid aud 1', 'invalid aud 2', payload['aud']]))).to be(subject)
      expect(-> { subject.validate_audience!(Set.new(['invalid aud 1', 'invalid aud 2'])) })
        .to raise_error AccessToken::TokenError
    end

    it 'should return self if audience match' do
      expect(subject.validate_audience!(payload['aud'])).to be(subject)
    end
  end

  describe 'extract' do
    let(:raw_jwt_token) { JWT.encode payload, rsa_private, 'RS256' }

    let(:valid_cert) do
      create_x509_cert public_key: rsa_public
    end

    let(:invalid_cert) do
      create_x509_cert
    end

    it 'should decode provided raw JWT data and create new instance' do
      access_token = described_class.extract raw_jwt_token, [valid_cert]
      expect(access_token.payload).to eql(payload)
    end

    it 'should support multiple certificates when decoding' do
      access_token = described_class.extract raw_jwt_token, [invalid_cert, valid_cert, invalid_cert]
      expect(access_token.payload).to eql(payload)
    end

    it 'should raise error if certificates does not match' do
      expect(lambda do
        described_class.extract raw_jwt_token, [invalid_cert]
      end).to raise_error(AccessToken::TokenError)
    end
  end

  describe 'google_certificates' do
    let(:cert1) do
      create_x509_cert
    end

    let(:cert2) do
      create_x509_cert
    end

    before(:each) do
      @stub = stub_request(:get, described_class::GOOGLE_CERTS_URI)
              .to_return(body: {
                'certificate-1' => cert1.to_s,
                'certificate-2' => cert2.to_s
              }.to_json)
      described_class.forget_google_certificates
    end

    it 'should download google certificates and return them as an array' do
      certificates = described_class.google_certificates
      expect(certificates.length).to eql 2
      expect(certificates.map(&:subject)).to include(cert1.subject, cert2.subject)
    end

    it 'should cache downloaded certificates' do
      certificates1 = described_class.google_certificates
      certificates2 = described_class.google_certificates
      expect(@stub).to have_been_made.once
      expect(certificates1).to be certificates2
    end

    it 'should raise error google response was not 200' do
      stub_request(:get, described_class::GOOGLE_CERTS_URI).to_return(status: [500, 'Internal Server Error'])
      expect { described_class.google_certificates }.to raise_error RuntimeError, 'Failed to get certificates: 500 - Internal Server Error'
    end
  end
end
