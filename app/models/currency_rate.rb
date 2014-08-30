class CurrencyRate < ActiveRecord::Base
  include Loggable
  
  class << self
    def get from: [], to: nil
      log.debug "Getting rates from: #{from}, to: #{to}"
      from = from.to_set
      rates = Hash[ CurrencyRate.where(from: from.to_a, to: to).map { |rate| [rate.from, rate] } ]
      yesterday = DateTime.now.yesterday
     
      to_create = from.select { |f| !rates.key?(f) }
      to_update = rates.select { |k, r| r.updated_at <= yesterday }.map { |k, r| k }
      to_fetch = to_create + to_update
      
      if to_fetch.length > 0
        log.debug "#{to_fetch.length} rates to fetch. New: #{to_create}, outdated: #{to_update}"
        fetched = fetch(from: to_fetch, to: to)
        fetched.each { |rate|
          log.debug "Processing fetched rate: #{rate}"
          if to_create.include?(rate[:from])
            log.debug "Creating new rate."
            rates[rate[:from]] = CurrencyRate.create! rate
          else
            log.debug "Updating outdated rate."
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
    
    YqlServiceUrl = "https://query.yahooapis.com/v1/public/yql"
    private def fetch from: nil, to: nil
      # Sample query to be executed
      # https://query.yahooapis.com/v1/public/yql?q=select * from yahoo.finance.xchange where pair in ("USDUAH", "EURUAH")&format=json&env=store://datatables.org/alltableswithkeys
      
      inComponent = from.map { |from_code| %("#{from_code}#{to}") }.join(',')
      yqlQuery = "select * from yahoo.finance.xchange where pair in(#{inComponent})"
      data_uri = URI.parse(YqlServiceUrl)
      data_uri.query = "q=#{URI.encode(yqlQuery)}&format=json&env=store://datatables.org/alltableswithkeys"
      log.debug "Sending YQL query: #{yqlQuery}"
      response = Net::HTTP.get_response(data_uri)
      if response.code != "200"
        raise "Failed to download currencies from #{data_uri}. #{response.code} #{response.message}"
      end
      result = JSON.parse response.body
      rates = []
      rate = result['query']['results']['rate']
      if from.length > 1
        result['query']['results']['rate'].each { |rate| process_raw_rate rates, rate, to }
      else
        process_raw_rate rates, result['query']['results']['rate'], to
      end
      rates
    end
    
    private def process_raw_rate rates, raw_rate, to
      log.debug "Raw fetched rate: #{raw_rate}"
      from = raw_rate['id'].gsub(to, '')
      rates << {from: from, to: to, rate: raw_rate['Rate']}
    end
  end
end
