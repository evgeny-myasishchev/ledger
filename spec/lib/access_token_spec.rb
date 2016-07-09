require 'rails_helper'

describe AccessToken do
  describe 'ensure_audience!' do
    it 'should raise error if audience mismatch' do
    end

    it 'should return self if audience match' do
    end
  end

  describe 'extract' do
    it 'should decode provided raw JWT data and create new instance' do
    end

    it 'should raise error if certificates does not match' do
    end
  end
end
