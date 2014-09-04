require 'net/http'
require 'rexml/document'

class CurrenciesUpdater
  def initialize(options)
    @options = {
      logger: nil,
      data_uri: 'http://www.currency-iso.org/dam/downloads/table_a1.xml',
      output: File.expand_path('../../config/initializers/register-currencies.rb', __FILE__)
    }.merge! options
    if(@options[:logger].nil?)
      require 'logger'
      @options[:logger] = Logger.new(STDOUT)
    end
  end
  
  def update
    log.info "Updating currencies."
    currencies_xml = get_currencies_xml URI.parse(@options[:data_uri])
    currencies = parse_currencies_xml currencies_xml
    write currencies, @options[:output]
    log.info 'Currencies updated.'
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
            english_name: currency_data.get_text('CcyNm').value,
            code: currency_data.get_text('Ccy').value,
            id: currency_data.get_text('CcyNbr').value
          }
        rescue
          log.error "Failed to parse currency xml data:\n #{currency_data}."
          raise
        end
      }
    end
    
    # Currency codes whos units are ounces (oz)
    OzCurrencies = Set.new(['XAU', 'XAG', 'XPD', 'XPT'])
    
    def write(currencies, output)
      log.debug "Writting parsed currencies. Output: #{output}"
      registered = Set.new
      File.open output, 'w' do |file|
        file.write "#\n"
        file.write "# Autogenerated file. Do not edit manually. Generated with CurrenciesUpdater\n"
        file.write "# Source url: #{@options[:data_uri]}\n"
        file.write "#\n"
        currencies.each { |currency|
          next if currency[:code] == 'XTS'
          unless registered.include?(currency[:code])
            file.write %(Currency.register id: #{currency[:id].to_i}, code: '#{currency[:code]}', english_name: '#{currency[:english_name]}')
            file.write %(, unit: 'ozt') if OzCurrencies.include?(currency[:code])
            file.write %(\n)
            registered << currency[:code]
          end
        }
      end
    end
    
  class << self
    def update(options = {})
      new(options).update
    end
  end
end