class Currency
  attr_reader :english_name, :alpha_code, :numeric_code
  
  def initialize(attribs)
    @english_name = get_required_attrib attribs, :english_name
    @alpha_code = get_required_attrib attribs, :alpha_code
    @numeric_code = get_required_attrib attribs, :numeric_code
  end
  
  def ==(other)
    return english_name == other.english_name && 
      alpha_code == other.alpha_code && 
      numeric_code == other.numeric_code
  end
  
  def eql?(other)
    self == other
  end
  
  private
    def get_required_attrib attribs, key
      raise ArgumentError.new("#{key} attribute is missing.") if !attribs.key?(key) || attribs[key].blank?
      attribs[key]
    end
  
  class << self
    def [](alpha_code)
      get_by_code alpha_code
    end
    
    # Get the currency instance by alpha code
    def get_by_code(alpha_code)
      raise ArgumentError.new "#{alpha_code} is unknown currency." unless currencies_by_code.key?(alpha_code)
      currencies_by_code[alpha_code]
    end
    
    # Register the currency with specified attributes
    def register(attribs)
      currency = Currency.new(attribs)
      raise ArgumentError.new "currency #{currency.alpha_code} already registered." if currencies_by_code.key?(currency.alpha_code)
      currencies_by_code[currency.alpha_code] = currency
    end
    
    def clear!
      currencies_by_code.clear
    end
    
    private
      def currencies_by_code
        @currencies_by_code ||= {}
      end
  end
end
