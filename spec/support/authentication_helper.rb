module AuthenticationHelper
  module ClassMethods
    def authenticate_user
      let(:user) { User.create!(email: "test@mail.com", password: 'test-test-12') }
    
      before(:each) do
        sign_in :user, user
      end
    end
  end
    
  def self.included(receiver)
    receiver.extend ClassMethods
  end
end