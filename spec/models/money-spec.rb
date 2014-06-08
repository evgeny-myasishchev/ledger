require 'spec_helper'

describe Money do
  let(:uah) { Currency['UAH'] }
  before(:all) do
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
      nodes[0].to_ruby.should eql :integer_ammount
      nodes[1].to_ruby.should eql subject.integer_ammount
      nodes[2].to_ruby.should eql :currency
      nodes[3].to_ruby.should eql uah.code
    end
    
    it "should deserialize correctly" do
      subject = Money.new 10050, uah
      data = YAML.dump subject
      actual = YAML.load data
      actual.should be_instance_of(Money)
      actual.integer_ammount.should equal(subject.integer_ammount)
      actual.currency.should be uah
    end
  end
  
  describe "equality" do
    specify "== and eql? should check attributes equality" do
      money1 = Money.parse('100.41', Currency['UAH'])
      money2 = Money.parse('100.41', Currency['EUR'])
      money3 = Money.parse('100.41', Currency['EUR'])
      
      money1.should_not eql money2
      money1.should_not == money2
      money2.should eql money3
      money2.should == money3
    end
  end
  
  describe "self.parse" do
    describe "from string using current locale" do
      it "should parse integer" do
        money = Money.parse('9932', uah)
        money.integer_ammount.should eql 9932
        money.currency.should be uah
      end
      
      it "should parse with separator" do
        money = Money.parse('10,05', uah)
        money.integer_ammount.should eql 1005
        money.currency.should be uah
        
        money = Money.parse('10,5', uah)
        money.integer_ammount.should eql 1050
      end
      
      it "should parse with thousands delimiter" do
        money = Money.parse('100.110,05', uah)
        money.integer_ammount.should eql 10011005
      end
      
      it "should fail if fractional part takes more than 2 dights" do
        lambda { Money.parse('0,003', uah) }.should raise_error(Money::MoneyParseError, "Can not parse 0,003. Fractional part is longer than two dights.")
      end
            
      it "should fail more than two parts" do
        lambda { Money.parse('0,0,003', uah) }.should raise_error(Money::MoneyParseError, "Can not parse 0,0,003. Unexpected number of parts.")
      end
    end
    
    it "should parse from floats" do
      money = Money.parse(10.05, uah)
      money.integer_ammount.should eql 1005
      money.currency.should be uah
      
      money = Money.parse(10.5, uah)
      money.integer_ammount.should eql 1050
    end
    
    it "should parse integers" do
      money = Money.parse(1005, uah)
      money.integer_ammount.should eql 1005
      money.currency.should be uah
    end
  end
end