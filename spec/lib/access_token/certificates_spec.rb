require 'rails_helper'

describe AccessToken::Certificates do
  describe 'get_certificate' do
    let(:subject) { described_class }

    it 'should get certificate for given jwt header from known issuer' do
      known_iss1 = random_string('iss1')
      known_iss2 = random_string('iss2')
      provider1 = instance_double(described_class::BaseProvider)
      provider2 = instance_double(described_class::BaseProvider)

      allow(subject).to receive(:providers) {
                          {
                            known_iss1 => provider1,
                            known_iss2 => provider2
                          } }
      jwt_header1 = { 'kid' => random_string('kid1') }
      jwt_body1 = { 'iss' => known_iss1 }
      jwt_header2 = { 'kid' => random_string('kid2') }
      jwt_body2 = { 'iss' => known_iss2 }
      cert1 = create_x509_cert
      cert2 = create_x509_cert
      expect(provider1).to receive(:get_certificate).with(jwt_header1) { cert1 }
      expect(provider2).to receive(:get_certificate).with(jwt_header2) { cert2 }
      expect(subject.get_certificate(jwt_header1, jwt_body1)).to eql cert1
      expect(subject.get_certificate(jwt_header2, jwt_body2)).to eql cert2
    end

    it 'should raise TokenError for unknown issuer' do
      unknown_iss = random_string('unknown-iss')
      jwt_header = { 'kid' => random_string('kid1') }
      jwt_body = { 'iss' => unknown_iss }
      expect { subject.get_certificate(jwt_header, jwt_body) }
        .to raise_error(AccessToken::TokenError, "Unknown issuer: #{unknown_iss}")
    end
  end

  describe AccessToken::Certificates::GoogleProvider do
    describe 'get_certificate' do
      let(:kid1) { random_string('kid1') }
      let(:kid2) { random_string('kid2') }
      let(:kid3) { random_string('kid3') }
      let(:initial_certs) do
        {
          kid1 => create_x509_cert,
          kid2 => create_x509_cert,
          kid3 => create_x509_cert
        }
      end

      let(:new_kid) { random_string('kid') }
      subject { described_class.new(initial_certs, verbose: true) }

      before(:each) do
        @api_call = stub_request(:get, described_class::GOOGLE_CERTS_URI)
                    .to_return(body: {
                      new_kid => create_x509_cert.to_s
                    }.to_json)
      end

      it 'should return matching certificate for given kid' do
        expect(subject.get_certificate('kid' => kid2)).to eql initial_certs[kid2]
        expect(subject.get_certificate('kid' => kid3)).to eql initial_certs[kid3]
      end

      it 'should fetch and cache new certificates from google api if no matching certificate found' do
        new_kid1 = random_string('new-kid1')
        new_cert_1 = create_x509_cert
        new_kid2 = random_string('new-kid2')
        new_cert_2 = create_x509_cert
        @api_call = stub_request(:get, described_class::GOOGLE_CERTS_URI)
                    .to_return(body: {
                      new_kid1 => new_cert_1.to_s,
                      new_kid2 => new_cert_2.to_s
                    }.to_json)
        expect(subject.get_certificate('kid' => new_kid1).subject).to eql new_cert_1.subject
        expect(subject.get_certificate('kid' => new_kid2).subject).to eql new_cert_2.subject
        expect(@api_call).to have_been_made.once
        expect(subject.cache[new_kid1].subject).to eql new_cert_1.subject
        expect(subject.cache[new_kid2].subject).to eql new_cert_2.subject
      end

      it 'should remove expired certificates from cache' do
        subject.cache[kid1] = create_x509_cert not_after: Time.now - 1
        subject.get_certificate 'kid' => new_kid
        expect(subject.cache).not_to have_key kid1
      end

      it 'should raise error google response was not 200' do
        stub_request(:get, described_class::GOOGLE_CERTS_URI).to_return(status: [500, 'Internal Server Error'])
        expect { subject.get_certificate('kid' => random_string) }
          .to raise_error RuntimeError, 'Failed to get certificates: 500 - Internal Server Error'
      end

      it 'should raise TokenError if required cert not found' do
        not_existing_kid = random_string('not-existing-kid')
        expect { subject.get_certificate('kid' => not_existing_kid) }
          .to raise_error AccessToken::TokenError, "Certificate with kid=#{not_existing_kid} not found"
      end
    end
  end
end
