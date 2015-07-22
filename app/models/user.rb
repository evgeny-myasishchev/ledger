require 'openssl'

class User < ActiveRecord::Base
  has_many :device_secrets

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:google_oauth2] 

  def self.from_omniauth(auth)
    find_or_initialize_by(email: auth.info.email) do |user|
      user.password = Devise.friendly_token[0,20]
    end
  end

  def get_device_secret(device_id)
    secrets = device_secrets.where(device_id: device_id)
    secrets.any? ? secrets.first : nil
  end

  def add_device_secret(device_id, name)
    secret = DeviceSecret.new device_id: device_id, name: name, secret: generate_new_secret
    device_secrets << secret
    secret
  end

  def reset_device_secret(id)
    secret = device_secrets.find(id)
    secret.secret = generate_new_secret
    secret.save!
  end

  def remove_device_secret(id)
    secret = device_secrets.find(id)
    device_secrets.destroy secret
  end

  private def generate_new_secret
    cipher = OpenSSL::Cipher::AES256.new(:CBC)
    Base64.encode64(cipher.random_key)
  end
end
