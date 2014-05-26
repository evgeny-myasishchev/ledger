class Money
  class MoneyParseError < StandardError
    
  end
  
  attr_reader :integer_ammount, :currency
  def initialize(integer_ammount, currency)
    @integer_ammount, @currency = integer_ammount, currency
  end
  
  class << self
    # Parse the ammount and constructs the Money class
    # Following values are accepted:
    # - floating point numbers like: 10.02
    # - strings in form: 10.02
    #
    # Notes when parsing strings: 
    # - I18n.t 'number.currency.format.separator' is used as a decimal separator and 
    # - I18n.t 'number.currency.format.delimiter' is used as thousands delimiter
    def parse(ammount, currency)
      if ammount.is_a? String
        parse_string ammount, currency
      elsif ammount.is_a? Float
        parse_float ammount, currency
      elsif ammount.is_a? Integer
        new ammount, currency
      else
        raise "Can not parse ammount #{ammount} of type #{ammount.class}"
      end
    end
    
    private 
      def parse_string ammount, currency
        separator = I18n.t :'number.currency.format.separator'
        delimiter = I18n.t :'number.currency.format.delimiter'
        parts = ammount.split(separator)
        raise MoneyParseError.new("Can not parse #{ammount}. Unexpected number of parts.") if parts.length > 2
        integer = parts[0]
        integer.delete! delimiter
        fraction = parts.length == 2 ? parts[1] : nil
        return new(integer.to_i, currency) if fraction.nil?
        raise MoneyParseError.new("Can not parse #{ammount}. Fractional part is longer than two dights.") if fraction.length > 2
        return new((integer + fraction.ljust(2, '0')).to_i, currency)
      end
        
      def parse_float ammount, currency
        str_ammount = ammount.to_s
        separator = I18n.t :'number.currency.format.separator'
        str_ammount.gsub!('.', separator) unless separator == '.'
        parse_string str_ammount, currency
      end
  end
end