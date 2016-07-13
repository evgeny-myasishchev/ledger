require 'rails_helper'

describe AccessToken do
  let(:rsa_private) { OpenSSL::PKey::RSA.generate 2048 }
  let(:rsa_public) { rsa_private.public_key }
  let(:subject) { described_class.new payload }

  let(:payload) do
    {
      'aud' => FFaker::Internet.domain_name
    }
  end

  describe 'validate_audience!' do
    it 'should raise error if audience mismatch' do
      expect(-> { subject.validate_audience!('invlaid audience') })
        .to raise_error AccessToken::TokenError
    end

    it 'validate audience as an array' do
      expect(subject.validate_audience!(['invalid aud 1', 'invalid aud 2', payload['aud']])).to be(subject)
    end

    it 'should return self if audience match' do
      expect(subject.validate_audience!(payload['aud'])).to be(subject)
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
      end).to raise_error(AccessToken::TokenError)
    end
  end

  describe 'google_certificates' do
    def create_cert(subject)
      cert = OpenSSL::X509::Certificate.new
      cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
      cert.not_before = Time.now
      cert.not_after = Time.now + 1000
      cert.public_key = OpenSSL::PKey::RSA.generate(2048).public_key
      cert.sign rsa_private, OpenSSL::Digest::SHA1.new
      cert
    end

    let(:cert1) do
      create_cert '/C=BE/O=Test/OU=Test/CN=Test1'
    end

    let(:cert2) do
      create_cert '/C=BE/O=Test/OU=Test/CN=Test2'
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
