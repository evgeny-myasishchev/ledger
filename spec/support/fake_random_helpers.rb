module FakeRandomHelpers
  def random_string(prefix = nil, length: 20)
    prefix ? "#{prefix}-#{SecureRandom.hex(length)}" : SecureRandom.hex(length)
  end
end

RSpec.configure do |config|
  config.include FakeRandomHelpers
end
