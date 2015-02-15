namespace :ledger do
  namespace :tests do
    task :http_report_transactions do |args|
      options = {
        number: 20
      }
      parser = OptionParser.new(args) do |opts|
        opts.banner = "Usage: rake ledger:tests:http_report_transactions -- [options]"
        
        opts.on("-u", "--user USERNAME","User's email address", String) do |user|
          options[:user] = user
        end
        opts.on("-p", "--password PASSWORD","User's password", String) do |pass|
          options[:password] = pass
        end
        opts.on("--url URL","Ledger url", String) do |url|
          options[:url] = url
        end
        opts.on("--account-id ACCOUNT_ID","Account to report transactions for", String) do |account_id|
          options[:account_id] = account_id
        end
        opts.on("--number number","Number of transactions to report", String) do |number|
          options[:number] = number.to_i
        end
      end
      parser.parse!
      
      raise ArgumentError.new 'url is required' unless options[:url]
      raise ArgumentError.new 'user is required' unless options[:user]
      raise ArgumentError.new 'password is required' unless options[:password]
      raise ArgumentError.new 'account-id is required' unless options[:account_id]
      
      log = Logger.new STDOUT
      
      require 'rest-client'
      RestClient.log = log
      
      base_url = options[:url]
      
      log.info "Loger url: #{base_url}. User: #{options[:user]}"
      
      response = RestClient.get URI.join(base_url, '/users/sign_in').to_s
      session_cookies = {'_ledger_session' => response.cookies['_ledger_session'] }
      authenticity_token = response.match(/<meta content="(.*)" name="csrf-token" \/>/)[1]
      log.debug "The authenticity_token and cookie retrieved. Authenticating..."
      authenticated = false
      RestClient.post(URI.join(base_url, '/users/sign_in').to_s,
        {authenticity_token: authenticity_token,  'user[email]' => options[:user], 'user[password]' => options[:password]},
        {cookies: session_cookies, accept: :html}) do |response, request, result, &block|
          case response.code
            when 200
              raise 'Authentication failed' unless authenticated
              session_cookies = {'_ledger_session' => response.cookies['_ledger_session'] }
              authenticity_token = response.match(/<meta content="(.*)" name="csrf-token" \/>/)[1]
            when 302
              authenticated = true
              response.args[:method] = :get
              response.return!(request, result, &block)
            else
              response.return!(request, result, &block)
            end
        end
        
      options[:number].times do |i|
        log.debug "Generating transaction: #{i}"
        RestClient.post(URI.join(base_url, "accounts/#{options[:account_id]}/transactions/report-expence").to_s, 
          {
            authenticity_token: authenticity_token,
            command: {
              account_id: options[:account_id],
              amount: 100,
              comment: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
              date: DateTime.now,
              is_transfer: false,
              tag_ids:[],
              transaction_id: SecureRandom.uuid
            }
          }, {cookies: session_cookies})
      end
    end
  end
end