require 'rails_helper'

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
      subject = described_class.new english_name: 'Hryvnia', code: 'UAH', id: 980
      expect(subject.english_name).to eql 'Hryvnia'
      expect(subject.code).to eql 'UAH'
      expect(subject.id).to eql 980
    end
    
    it "should raise error if any attribute is missing" do
      expect { described_class.new code: 'UAH', id: 980 }.to raise_error(ArgumentError, 'english_name attribute is missing.')
      expect { described_class.new english_name: '', code: 'UAH', id: 980 }.to raise_error(ArgumentError, 'english_name attribute is missing.')
        
      expect { described_class.new english_name: 'Hryvnia', id: 980 }.to raise_error(ArgumentError, 'code attribute is missing.')
      expect { described_class.new english_name: 'Hryvnia', code: '', id: 980 }.to raise_error(ArgumentError, 'code attribute is missing.')
        
      expect { described_class.new english_name: 'Hryvnia', code: 'UAH' }.to raise_error(ArgumentError, 'id attribute is missing.')
      expect { described_class.new english_name: 'Hryvnia', code: 'UAH', id: nil }.to raise_error(ArgumentError, 'id attribute is missing.')
    end
  end
  
  describe "global registry" do
    before(:each) do
      described_class.register english_name: 'Hryvnia', code: 'UAH', id: 980
      described_class.register english_name: 'Euro', code: 'EUR', id: 978
    end
    
    specify "registered currency is possible to get by code" do
      expect(Currency.get_by_code('UAH').code).to eql 'UAH'
      expect(Currency['UAH'].code).to eql 'UAH'
    end
    
    it "should raise error if trying to get not existing currency" do
      expect(lambda { Currency.get_by_code('UNKNOWN') }).to raise_error(ArgumentError, "UNKNOWN is unknown currency.")
      expect(lambda { Currency['UNKNOWN'] }).to raise_error(ArgumentError, "UNKNOWN is unknown currency.")
    end
    
    it "should not allow registering same currency twice" do
      expect { described_class.register english_name: 'Euro', code: 'EUR', id: 978 }
        .to raise_error(ArgumentError, "currency EUR already registered.")
    end
    
    it "is possible to get if the currency is known" do
      expect(Currency).to be_known('UAH')
      expect(Currency).to be_known('EUR')
      expect(Currency).not_to be_known('XX1')
      expect(Currency).not_to be_known('XX2')
    end
    
    it "is possible to get all known currencies as an array" do
      known = Currency.known
      expect(known.length).to eql(2)
      expect(known.detect { |c| c.code == 'UAH' }).to be Currency['UAH']
      expect(known.detect { |c| c.code == 'EUR' }).to be Currency['EUR']
    end
  end
  
  describe "equality" do
    specify "== and eql? should check attributes equality" do
      uah1 = Currency.new english_name: 'Hryvnia', code: 'UAH', id: 980
      uah2 = Currency.new english_name: 'Hryvnia', code: 'UAH', id: 980
      eur = Currency.new english_name: 'Euro', code: 'EUR', id: 978
      
      expect(uah1 == uah2).to be_truthy
      expect(uah1).to eql uah2
      expect(uah1 == eur).to be_falsey
      expect(uah1).not_to eql eur
    end
  end
  
  describe "save/restore" do
    before(:each) do
      described_class.register english_name: 'Hryvnia', code: 'UAH', id: 980
      described_class.register english_name: 'Euro', code: 'EUR', id: 978
    end
    
    it "should remember currencies and restore them if cleared or changed" do
      described_class.save('point-1')
      described_class.clear!

      described_class.register english_name: 'Gold', code: 'XAU', id: 959
      described_class.register english_name: 'Palladium', code: 'XPD', id: 964
      described_class.save('point-2')

      described_class.restore('point-1')
      expect(Currency.known.length).to eql(2)
      expect(Currency).to be_known('UAH')
      expect(Currency).to be_known('EUR')
      
      described_class.restore('point-2')
      expect(Currency.known.length).to eql(2)
      expect(Currency).to be_known('XAU')
      expect(Currency).to be_known('XPD')
    end
    
    it "should fail to restore if no such backup" do
      expect(lambda { described_class.restore('unknown-1') }).to raise_error(ArgumentError, 'there is no such backup unknown-1')
    end
  end
end
