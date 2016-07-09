class AccessToken
  def initialize(payload)
  end

  def ensure_audience!(client_id)
  end

  class << self
    def extract(raw_jwt_token, certificates)
    end
  end
end
