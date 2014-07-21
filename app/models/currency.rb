class Currency
  # Numeric code of the currency
  attr_reader :id
  
  # Alpha code of the currency
  attr_reader :code
  
  # English name of the currency
  attr_reader :english_name
  
  def initialize(attribs)
    @english_name = get_required_attrib attribs, :english_name
    @code = get_required_attrib attribs, :code
    @id = get_required_attrib attribs, :id
  end
  
  def ==(other)
    return english_name == other.english_name && 
      code == other.code && 
      id == other.id
  end
  
  def eql?(other)
    self == other
  end
  
  def to_s
    "numeric code: #{id}, alpha_code: #{code}, english_name: #{english_name}"
  end
  
  private
    def get_required_attrib attribs, key
      raise ArgumentError.new("#{key} attribute is missing.") if !attribs.key?(key) || attribs[key].blank?
      attribs[key]
    end
  
  class << self
    def store
      Rails.application.currencies_store
    end
    
    def known?(code)
      currencies_by_code.key?(code)
    end
    
    def known
      currencies_by_code.values.dup
    end
    
    def [](code)
      get_by_code code
    end
    
    # Get the currency instance by alpha code
    def get_by_code(code)
      raise ArgumentError.new "#{code} is unknown currency." unless known?(code)
      currencies_by_code[code]
    end
    
    # Register the currency with specified attributes
    def register(attribs)
      currency = Currency.new(attribs)
      raise ArgumentError.new "currency #{currency.code} already registered." if known?(currency.code)
      currencies_by_code[currency.code] = currency
    end
    
    def clear!
      currencies_by_code.clear
    end
    
    def save(backup_id)
      backups_by_id[backup_id] = currencies_by_code.dup
    end
    
    def restore(backup_id)
      raise ArgumentError.new "there is no such backup #{backup_id}" unless backups_by_id.key?(backup_id)
      store[:currencies_by_code] = backups_by_id[backup_id]
    end
    
    private
      def currencies_by_code
        store[:currencies_by_code] ||= {}
      end
      
      def backups_by_id
        store[:backups_by_id] ||= {}
      end
  end
end
