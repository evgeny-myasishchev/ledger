module AccessTokenHelpers
  def generate_rsa_private(key_sise: 512)
    OpenSSL::PKey::RSA.generate key_sise
  end

  def create_x509_cert(subject: "/C=BE/O=Test/OU=Test/CN=#{FFaker::Internet.domain_name}",
                       not_before: Time.now - 1000,
                       not_after: Time.now + 1000,
                       public_key: generate_rsa_private.public_key,
                       sign_key: generate_rsa_private)
    cert = OpenSSL::X509::Certificate.new
    cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
    cert.not_before = not_before
    cert.not_after = not_after
    cert.public_key = public_key
    cert.sign sign_key, OpenSSL::Digest::SHA1.new
    cert
  end
end

RSpec.configure do |config|
  config.include AccessTokenHelpers
end
