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
            outdated.save!
            rates[rate[:from]] = outdated
          end
        }
      end
      rates.values
    end
    
    def fetch from: nil, to: nil
      raise "Not implemented"
    end
  end
end
