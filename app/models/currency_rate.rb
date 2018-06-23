class CurrencyRate < ActiveRecord::Base
  include Loggable
  
  class << self
    def get from: [], to: nil
      logger.debug "Getting rates from: #{from}, to: #{to}"
      from = from.to_set
      rates = Hash[ CurrencyRate.where(from: from.to_a, to: to).map { |rate| [rate.from, rate] } ]
      yesterday = DateTime.now.yesterday
     
      to_create = from.select { |f| !rates.key?(f) }
      to_update = rates.select { |k, r| r.updated_at <= yesterday }.map { |k, r| k }
      to_fetch = to_create + to_update
      
      if to_fetch.length > 0
        logger.debug "#{to_fetch.length} rates to fetch. New: #{to_create}, outdated: #{to_update}"
        fetched = fetch(from: to_fetch, to: to)
        fetched.each { |rate|
          logger.debug "Processing fetched rate: #{rate}"
          if to_create.include?(rate[:from])
            logger.debug "Creating new rate."
            rates[rate[:from]] = CurrencyRate.create! rate
          else
            logger.debug "Updating outdated rate."
            outdated = CurrencyRate.find_by(from: rate[:from], to: rate[:to])
            outdated.rate = rate[:rate]
            if outdated.changed?
              outdated.save!
            else
              #Making sure updated_at date is set to current so next update will occur in 24 hours.
              outdated.touch
            end
            rates[rate[:from]] = outdated
          end
        }
      end
      rates.values
    end
    
    ExchangeServiceUrl = "https://www.alphavantage.co/query"
    private def fetch from: nil, to: nil
      # Sample query to be executed
      # curl https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=USD&to_currency=UAH&apikey=xxx
      return from.map { |from_code| 
        data_uri = URI.parse(ExchangeServiceUrl)
        data_uri.query = "function=CURRENCY_EXCHANGE_RATE&from_currency=#{from_code}&to_currency=#{to}&apikey=#{ENV['ALPHAVANTAGE_API_KEY']}"
        logger.debug "Fetching rate for: #{from_code} -> #{to}"
        response = Net::HTTP.get_response(data_uri)
        if response.code != "200"
          raise "Failed to download currencies from #{data_uri}. #{response.code} #{response.message}"
        end
        result = JSON.parse response.body
        if result.key?('Error Message')
            raise result['Error Message']
        end
        rate = result['Realtime Currency Exchange Rate']['5. Exchange Rate']
        { from: from_code, to: to, rate: rate.to_f }
      }
    end
  end
end
