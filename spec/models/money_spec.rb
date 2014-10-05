require 'rails_helper'

describe Money do
  let(:uah) { Currency['UAH'] }
  before(:all) do
    unless I18n.available_locales.include?(:money_spec_locale)
      I18n.available_locales = I18n.available_locales + [:money_spec_locale]
    end
    I18n.backend.store_translations :money_spec_locale, {number: {currency: {
      format: {
        separator: ',',
        delimiter: '.'
      }
    }}}
    @original_locale = I18n.locale
    I18n.locale = :money_spec_locale
  end
  after(:all) { I18n.locale = @original_locale }
  
  describe "yaml serialization" do
    it "should serialize to yaml storing currency as a numeric code" do
      subject = Money.new 10050, uah
      data = YAML.dump subject
      doc = YAML.parse data
      nodes = doc.root.to_a
      expect(nodes[0].to_ruby).to eql :integer_amount
      expect(nodes[1].to_ruby).to eql subject.integer_amount
      expect(nodes[2].to_ruby).to eql :currency
      expect(nodes[3].to_ruby).to eql uah.code
    end
    
    it "should deserialize correctly" do
      subject = Money.new 10050, uah
      data = YAML.dump subject
      actual = YAML.load data
      expect(actual).to be_instance_of(Money)
      expect(actual.integer_amount).to equal(subject.integer_amount)
      expect(actual.currency).to be uah
    end
  end
  
  describe "equality" do
    specify "== and eql? should check attributes equality" do
      money1 = Money.parse('100.41', Currency['UAH'])
      money2 = Money.parse('100.41', Currency['EUR'])
      money3 = Money.parse('100.41', Currency['EUR'])
      
      expect(money1).not_to eql money2
      expect(money1 == money3).to be_falsey
      expect(money2).to eql money3
      expect(money2 == money3).to be_truthy
    end
  end
  
  describe "self.parse" do
    describe "from string using current locale" do
      it "should parse integer string" do
        money = Money.parse('9932', uah)
        expect(money.integer_amount).to eql 993200
        expect(money.currency).to be uah
      end
      
      it "should parse with separator" do
        money = Money.parse('10,05', uah)
        expect(money.integer_amount).to eql 1005
        expect(money.currency).to be uah
        
        money = Money.parse('10,5', uah)
        expect(money.integer_amount).to eql 1050
      end
      
      it "should parse with thousands delimiter" do
        money = Money.parse('100.110,05', uah)
        expect(money.integer_amount).to eql 10011005
      end
      
      it "should fail if fractional part takes more than 2 dights" do
        expect(lambda { Money.parse('0,003', uah) }).to raise_error(Money::MoneyParseError, "Can not parse 0,003. Fractional part is longer than two dights.")
      end
            
      it "should fail more than two parts" do
        expect(lambda { Money.parse('0,0,003', uah) }).to raise_error(Money::MoneyParseError, "Can not parse 0,0,003. Unexpected number of parts.")
      end
    end
    
    it "should parse from floats" do
      money = Money.parse(10.05, uah)
      expect(money.integer_amount).to eql 1005
      expect(money.currency).to be uah
      
      money = Money.parse(10.5, uah)
      expect(money.integer_amount).to eql 1050
    end
    
    it "should parse integers" do
      money = Money.parse(1005, uah)
      expect(money.integer_amount).to eql 1005
      expect(money.currency).to be uah
    end
  end
end