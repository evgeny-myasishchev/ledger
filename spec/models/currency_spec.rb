require 'spec_helper'

describe Currency do
  before(:all) do
    Currency.save('initial-currencies')
  end
  
  after(:all) do
    Currency.restore('initial-currencies')
  end
  
  before(:each) do
    described_class.clear!
  end
  
  describe "initialize" do
    it "should assign attributes" do
      subject = described_class.new english_name: 'Hryvnia', alpha_code: 'UAH', numeric_code: 980
      subject.english_name.should eql 'Hryvnia'
      subject.alpha_code.should eql 'UAH'
      subject.numeric_code.should eql 980
    end
    
    it "should raise error if any attribute is missing" do
      lambda { described_class.new alpha_code: 'UAH', numeric_code: 980 }
        .should raise_error(ArgumentError, 'english_name attribute is missing.')
      lambda { described_class.new english_name: '', alpha_code: 'UAH', numeric_code: 980 }
        .should raise_error(ArgumentError, 'english_name attribute is missing.')
        
      lambda { described_class.new english_name: 'Hryvnia', numeric_code: 980 }
        .should raise_error(ArgumentError, 'alpha_code attribute is missing.')
      lambda { described_class.new english_name: 'Hryvnia', alpha_code: '', numeric_code: 980 }
        .should raise_error(ArgumentError, 'alpha_code attribute is missing.')
        
      lambda { described_class.new english_name: 'Hryvnia', alpha_code: 'UAH' }
        .should raise_error(ArgumentError, 'numeric_code attribute is missing.')
      lambda { described_class.new english_name: 'Hryvnia', alpha_code: 'UAH', numeric_code: nil }
        .should raise_error(ArgumentError, 'numeric_code attribute is missing.')
    end
  end
  
  describe "global registry" do
    before(:each) do
      described_class.register english_name: 'Hryvnia', alpha_code: 'UAH', numeric_code: 980
      described_class.register english_name: 'Euro', alpha_code: 'EUR', numeric_code: 978
    end
    
    specify "registered currency is possible to get by code" do
      Currency.get_by_code('UAH').alpha_code.should eql 'UAH'
      Currency['UAH'].alpha_code.should eql 'UAH'
    end
    
    it "should raise error if trying to get not existing currency" do
      lambda { Currency.get_by_code('UNKNOWN') }.should raise_error(ArgumentError, "UNKNOWN is unknown currency.")
      lambda { Currency['UNKNOWN'] }.should raise_error(ArgumentError, "UNKNOWN is unknown currency.")
    end
    
    it "should not allow registering same currency twice" do
      lambda { described_class.register english_name: 'Euro', alpha_code: 'EUR', numeric_code: 978 }
        .should raise_error(ArgumentError, "currency EUR already registered.")
    end
    
    it "is possible to get if the currency is known" do
      Currency.should be_known('UAH')
      Currency.should be_known('EUR')
      Currency.should_not be_known('XX1')
      Currency.should_not be_known('XX2')
    end
    
    it "is possible to get all known currencies as an array" do
      known = Currency.known
      known.should have(2).items
      known.detect { |c| c.alpha_code == 'UAH' }.should be Currency['UAH']
      known.detect { |c| c.alpha_code == 'EUR' }.should be Currency['EUR']
    end
  end
  
  describe "equality" do
    specify "== and eql? should check attributes equality" do
      uah1 = Currency.new english_name: 'Hryvnia', alpha_code: 'UAH', numeric_code: 980
      uah2 = Currency.new english_name: 'Hryvnia', alpha_code: 'UAH', numeric_code: 980
      eur = Currency.new english_name: 'Euro', alpha_code: 'EUR', numeric_code: 978
      
      uah1.should == uah2
      uah1.should eql uah2
      uah1.should_not == eur
      uah1.should_not eql eur
    end
  end
  
  describe "save/restore" do
    before(:each) do
      described_class.register english_name: 'Hryvnia', alpha_code: 'UAH', numeric_code: 980
      described_class.register english_name: 'Euro', alpha_code: 'EUR', numeric_code: 978
    end
    
    it "should remember currencies and restore them if cleared or changed" do
      described_class.save('point-1')
      described_class.clear!

      described_class.register english_name: 'Gold', alpha_code: 'XAU', numeric_code: 959
      described_class.register english_name: 'Palladium', alpha_code: 'XPD', numeric_code: 964
      described_class.save('point-2')

      described_class.restore('point-1')
      Currency.known.should have(2).items
      Currency.should be_known('UAH')
      Currency.should be_known('EUR')
      
      described_class.restore('point-2')
      Currency.known.should have(2).items
      Currency.should be_known('XAU')
      Currency.should be_known('XPD')
    end
    
    it "should fail to restore if no such backup" do
      lambda { described_class.restore('unknown-1') }.should raise_error(ArgumentError, 'there is no such backup unknown-1')
    end
  end
end
