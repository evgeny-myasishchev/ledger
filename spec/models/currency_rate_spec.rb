require 'rails_helper'

RSpec.describe CurrencyRate, :type => :model do
  describe 'get' do
    before(:each) do
      @usduah = CurrencyRate.create! from: 'USD', to: 'UAH', rate: 13.6107
      @euruah = CurrencyRate.create! from: 'EUR', to: 'UAH', rate: 17.8889
    end
    
    it 'should get existing rates' do
      result = described_class.get(from: ['USD', 'EUR'], to: 'UAH')
      expect(result.count).to eql 2
      expect(result).to include @usduah
      expect(result).to include @euruah
    end
    
    it 'should fetch and save if no existing rates' do
      @usduah.delete
      @euruah.delete
      
      expect(described_class).to receive(:fetch).with(from: ['USD', 'EUR'], to: 'UAH').and_return(
        [{from: 'USD', to: 'UAH', rate: 13.6107}, {from: 'EUR', to: 'UAH', rate: 17.8889}]
      )
      result = described_class.get(from: ['USD', 'EUR'], to: 'UAH')
      expect(result.count).to eql 2
      expect(result).to include CurrencyRate.find_by(from: 'USD', to: 'UAH')
      expect(result).to include CurrencyRate.find_by(from: 'EUR', to: 'UAH')
    end
    
    it 'should fetch and save if existing rates are older than 24 hours' do
      @usduah.updated_at = @usduah.updated_at.yesterday
      @usduah.save!
      @euruah.updated_at = @usduah.updated_at.yesterday
      @euruah.save!
      
      expect(described_class).to receive(:fetch).with(from: ['EUR', 'USD'], to: 'UAH').and_return(
        [{from: 'USD', to: 'UAH', rate: 13.5012}, {from: 'EUR', to: 'UAH', rate: 17.7993}]
      )
      
      described_class.get(from: ['USD', 'EUR'], to: 'UAH')
      
      usduah = CurrencyRate.find_by(from: 'USD', to: 'UAH')
      expect(usduah.rate).to eql 13.5012
      euruah = CurrencyRate.find_by(from: 'EUR', to: 'UAH')
      expect(euruah.rate).to eql 17.7993
      
      result = described_class.get(from: ['USD', 'EUR'], to: 'UAH')
      expect(result.count).to eql 2
      expect(result).to include usduah
      expect(result).to include euruah
    end
  end
end
