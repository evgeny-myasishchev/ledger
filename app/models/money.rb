class Money
  class MoneyParseError < StandardError
  end
  
  attr_reader :integer_amount, :currency
  def initialize(integer_amount, currency)
    @integer_amount, @currency = integer_amount, currency
  end
  
  def to_s
    "[Money integer-amount: #{@integer_amount} currency: #{@currency.code}]"
  end
  
  def encode_with(coder)
    coder.add(:integer_amount, integer_amount)
    coder.add(:currency, currency.code)
  end
  
  def init_with(coder)
    @integer_amount = coder[:integer_amount]
    @currency = Currency[coder[:currency]]
  end
  
  def ==(other)
    return @integer_amount == other.integer_amount && @currency == other.currency
  end
  
  def eql?(other)
    self == other
  end
  
  class << self
    
    # Parse the amount and constructs the Money class
    # Following values are accepted:
    # - floating point numbers like: 10.02
    # - strings in form: 10.02
    #
    # Notes when parsing strings: 
    # - I18n.t 'number.currency.format.separator' is used as a decimal separator and 
    # - I18n.t 'number.currency.format.delimiter' is used as thousands delimiter
    def parse(amount, currency)
      if amount.is_a? String
        parse_string amount, currency
      elsif amount.is_a? Float
        parse_float amount, currency
      elsif amount.is_a? Integer
        new amount, currency
      else
        raise "Can not parse amount #{amount} of type #{amount.class}"
      end
    end
    
    private 
      def parse_string(amount, currency)
        separator = I18n.t :'number.currency.format.separator'
        delimiter = I18n.t :'number.currency.format.delimiter'
        parts = amount.gsub(/\s+/, '').split(separator)
        raise MoneyParseError.new("Can not parse #{amount}. Unexpected number of parts.") if parts.length > 2
        integer = parts[0]
        integer.delete! delimiter
        fraction = parts.length == 2 ? parts[1] : '00'
        return new(integer.to_i, currency) if fraction.nil?
        raise MoneyParseError.new("Can not parse #{amount}. Fractional part is longer than two dights.") if fraction.length > 2
        return new((integer + fraction.ljust(2, '0')).to_i, currency)
      end
        
      def parse_float(amount, currency)
        str_amount = amount.to_s
        separator = I18n.t :'number.currency.format.separator'
        str_amount.gsub!('.', separator) unless separator == '.'
        parse_string str_amount, currency
      end
  end
end