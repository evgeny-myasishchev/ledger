require 'spec_helper'

describe Currency do
  before(:each) do
    described_class.clear!
  end
  
  describe "initialize" do
    it "should assign attributes" do
      subject = described_class.new english_country_name: 'UKRAINE', english_name: 'Hryvnia', alpha_code: 'UAH', numeric_code: 980
      subject.english_country_name.should eql 'UKRAINE'
      subject.english_name.should eql 'Hryvnia'
      subject.alpha_code.should eql 'UAH'
      subject.numeric_code.should eql 980
    end
    
    it "should raise error if any attribute is missing" do
      lambda { described_class.new english_name: 'Hryvnia', alpha_code: 'UAH', numeric_code: 980 }
        .should raise_error(ArgumentError, 'english_country_name attribute is missing.')
      lambda { described_class.new english_country_name: '', english_name: 'Hryvnia', alpha_code: 'UAH', numeric_code: 980 }
        .should raise_error(ArgumentError, 'english_country_name attribute is missing.')
        
      lambda { described_class.new english_country_name: 'UKRAINE', alpha_code: 'UAH', numeric_code: 980 }
        .should raise_error(ArgumentError, 'english_name attribute is missing.')
      lambda { described_class.new english_country_name: 'UKRAINE', english_name: '', alpha_code: 'UAH', numeric_code: 980 }
        .should raise_error(ArgumentError, 'english_name attribute is missing.')
        
      lambda { described_class.new english_country_name: 'UKRAINE', english_name: 'Hryvnia', numeric_code: 980 }
        .should raise_error(ArgumentError, 'alpha_code attribute is missing.')
      lambda { described_class.new english_country_name: 'UKRAINE', english_name: 'Hryvnia', alpha_code: '', numeric_code: 980 }
        .should raise_error(ArgumentError, 'alpha_code attribute is missing.')
        
      lambda { described_class.new english_country_name: 'UKRAINE', english_name: 'Hryvnia', alpha_code: 'UAH' }
        .should raise_error(ArgumentError, 'numeric_code attribute is missing.')
      lambda { described_class.new english_country_name: 'UKRAINE', english_name: 'Hryvnia', alpha_code: 'UAH', numeric_code: nil }
        .should raise_error(ArgumentError, 'numeric_code attribute is missing.')
    end
  end
  
  describe "global registry" do
    before(:each) do
      described_class.register english_country_name: 'UKRAINE', english_name: 'Hryvnia', alpha_code: 'UAH', numeric_code: 980
      described_class.register english_country_name: 'GERMANY', english_name: 'Euro', alpha_code: 'EUR', numeric_code: 978
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
      lambda { described_class.register english_country_name: 'GERMANY', english_name: 'Euro', alpha_code: 'EUR', numeric_code: 978 }
        .should raise_error(ArgumentError, "currency EUR already registered.")
    end
  end
  
  describe "equality" do
    specify "== and eql? should check attributes equality" do
      uah1 = Currency.new english_country_name: 'UKRAINE', english_name: 'Hryvnia', alpha_code: 'UAH', numeric_code: 980
      uah2 = Currency.new english_country_name: 'UKRAINE', english_name: 'Hryvnia', alpha_code: 'UAH', numeric_code: 980
      eur = Currency.new english_country_name: 'GERMANY', english_name: 'Euro', alpha_code: 'EUR', numeric_code: 978
      
      uah1.should == uah2
      uah1.should eql uah2
      uah1.should_not == eur
      uah1.should_not eql eur
    end
  end
end
