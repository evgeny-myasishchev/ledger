require 'google-id-token-extractor'

describe GoogleIDToken::Extractor do
  describe 'extract' do
    let(:validator) { double(:validator) }
    before do
      allow(GoogleIDToken::Validator).to receive(:new) { validator }
      allow(validator).to receive(:check)
    end
    
    it 'should use validator to check the id token' do
      extracted_token = double(:extracted_token)
      expect(validator).to receive(:check).
        with('the id token', 'client-id-100', 'sender-client-id-100').
        and_return(extracted_token)
      actual = subject.class.extract('the id token', {'GOAUTH_CLIENT_ID' => 'client-id-100', 'GOAUTH_SENDER_CLIENT_ID' => 'sender-client-id-100'})
      expect(extracted_token).to be extracted_token
    end
    
    it 'should throw invalid token error (including problem) if check returns nil' do
      allow(validator).to receive(:check) { nil }
      allow(validator).to receive(:problem) { 'key check failure' }
      expect { subject.class.extract('the id token') }.to raise_error GoogleIDToken::InvalidTokenException, 'key check failure'
    end
  end
end