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
    
  end
end
