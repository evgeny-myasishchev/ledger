require 'net/http'
require 'rexml/document'

class CurrenciesUpdater
  def initialize(options)
    @options = {
      logger: nil,
      data_uri: 'http://www.currency-iso.org/dam/downloads/table_a1.xml'
    }.merge! options
    if(@options[:logger].nil?)
      require 'logger'
      @options[:logger] = Logger.new(STDOUT)
    end
  end
  
  def update
    log.info 'Loading currencies...'
    currencies_xml = get_currencies_xml URI.parse(@options[:data_uri])
    currencies = parse_currencies_xml currencies_xml
    write currencies
    log.info 'Currencies loaded.'
  end
  
  private
    def log
      @options[:logger]
    end
    
    def get_currencies_xml(data_uri)
      log.debug "Downloading currencies from #{data_uri}"
      response = Net::HTTP.get_response(data_uri)
      if response.code != "200"
        raise "Failed to download currencies from #{data_uri}. #{response.code} #{response.message}"
      end
      REXML::Document.new response.body
    end
    
    def parse_currencies_xml(xml)
      log.debug "Parsing currencies xml..."
      xml.root.get_elements('CcyTbl/CcyNtry')
        .select { |currency_data| !currency_data.get_text('Ccy').nil? }
        .map { |currency_data|
        begin
          {
            english_country_name: currency_data.get_text('CtryNm').value,
            english_name: currency_data.get_text('CcyNm').value,
            alpha_code: currency_data.get_text('Ccy').value,
            numeric_code: currency_data.get_text('CcyNbr').value
          }
        rescue
          log.error "Failed to parse currency xml data:\n #{currency_data}."
          raise
        end
      }
    end
    
    def write(currencies)
      log.debug "Writting parsed currencies. In total #{currencies.length} to write..."
      currencies.each { |currency| 
        begin
          Currency.create! currency 
        rescue
          log.error "Failed to create currency: #{currency}."
          raise
        end
      }
    end
    
  class << self
    def update(options = {})
      new(options).load
    end
  end
end