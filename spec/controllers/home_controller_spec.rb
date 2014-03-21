require 'spec_helper'

describe HomeController do
  describe "routes", :type => :routing do
    it "routes root to home/index" do
      {get: '/'}.should route_to controller: 'home', action: 'index'
    end
  end

  describe "GET 'index'" do
    describe "not authenticated" do
      it "redirects to new session url" do
        get 'index'
        response.should be_redirect
        response.should redirect_to(new_user_session_url)
      end
    end
  end
end
