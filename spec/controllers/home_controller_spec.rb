require 'spec_helper'

describe HomeController do
  describe "routes", :type => :routing do
    it "routes root to home/index" do
      {get: '/'}.should route_to controller: 'home', action: 'index'
    end
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end
  end
end
