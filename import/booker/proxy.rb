class Ledger::Import::BookerProxy
  include Loggable
  
  def initialize(url)
    @url = url
  end
  
  def authenticate(login, password)
    log.info "Authenticating on #{@url}"
    # sessions = RemoteController::Base.new("#{@url}/user_sessions")
    # sessions.cookies_container = @cookies_container
    log.debug 'Obtaining authenticity token'
    response = RestClient.get "#{@url}/user_sessions/new.html"
    @session_cookie = response.cookies['_thebablo_session']
    @authenticity_token = response.match(/<meta name="csrf-token" content="(.*)"\/>/)[1]
    log.debug "The authenticity_token retrieved: #{@authenticity_token}. Authenticating..."
    response = RestClient.post "#{@url}/user_sessions.json", {authenticity_token: @authenticity_token, 'user_session[email]' => login, 'user_session[password]' => password}, session_cookies
    @session_cookie = response.cookies['_thebablo_session']
  end
  
  def get_tags
    log.info 'Getting tags...'
    tags = RestClient.get "#{@url}/tags.json", session_cookies
    JSON.parse(tags)
  end
  
  def get_categories
    log.info 'Getting categories...'
    Hash.from_xml(RestClient.get "#{@url}/categories.xml", session_cookies)['categories']
  end
  
  def get_accounts
    log.info 'Getting accounts...'
    accounts = RestClient.get "#{@url}/accounts.json", session_cookies
    JSON.parse(accounts)['accounts']
  end
  
  def fetch_transactions(account_id, &block)
    limit = 20
    offset = 0
    has_more = false
    log.info "Fetching transactions for account: #{account_id}"
    begin
      data = JSON.parse(RestClient.get("#{@url}/transactions.json", session_cookies.merge(params: {account_id: account_id, limit: limit, offset: offset})))
      transactions = data['transactions']
      log.info "Fetched: #{offset + transactions.length} of #{data['total']}"
      yield(transactions)
      has_more = transactions.length == limit && data['total'] > (limit + offset)
      offset += limit
    end while has_more
  end
  
  private
    
    def session_cookies
      {cookies: {'_thebablo_session' => @session_cookie}}
    end
end