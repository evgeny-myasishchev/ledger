require 'rails_helper'

describe EventStoreClient::ConcurrentSubscription do
  let(:target) { instance_double(EventStoreClient::PersistentSubscription) }
  subject { described_class.new(target) }

  it 'should delegate add_handler and handlers to target' do
    handler = double(:handler)
    handlers = double(:handlers)
    expect(target).to receive(:add_handler).with(handler)
    expect(target).to receive(:handlers) { handlers }
    subject.add_handler handler
    expect(subject.handlers).to be handlers
  end

  describe 'pull' do
    it 'should schedule pulling of a target subscription in a separate thread' do
      mutex = Mutex.new
      pulled_condition = ConditionVariable.new
      target_pulled = false
      expect(target).to receive(:pull) do
        mutex.synchronize {
          target_pulled = true
          pulled_condition.signal
        }
      end
      subject.pull
      mutex.synchronize { pulled_condition.wait(mutex, 3) }
      expect(target_pulled).to be_truthy
    end

    it 'should pull once even if multiple pulls are scheduled' do
      mutex = Mutex.new
      pulled_condition = ConditionVariable.new
      pull_count = 0
      expect(target).to receive(:pull).at_least(:once) do
        pull_count += 1
        mutex.synchronize { pulled_condition.signal }
      end
      subject.pull #This should cause one pull that is immediately scheduled
      mutex.synchronize { pulled_condition.wait(mutex, 3) }
      expect(pull_count).to eql 1

      #Those three below should cause just one pull
      subject.pull
      subject.pull
      subject.pull
      mutex.synchronize { pulled_condition.wait(mutex, 3) }

      expect(pull_count).to eql 2
    end
  end
end