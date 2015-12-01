require 'rails_helper'

describe EventStoreClient::ConcurrentSubscription do
  include Loggable
  let(:target) { instance_double(EventStoreClient::PersistentSubscription, identifier: 'persistent-subscription') }
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
      pulled_multiple_condition = ConditionVariable.new
      @pull_count = 0
      expect(target).to receive(:pull).at_least(:once) do
        logger.debug 'Handling pull request.'
        mutex.synchronize {
          @pull_count += 1
          pulled_condition.signal
          logger.debug "Counter incremented to #{@pull_count}. Condition signalled."
          if @pull_count > 1
            logger.debug 'Waiting for multiple pull to complete'
            pulled_multiple_condition.wait(mutex, 3)
          end
        }
      end
      subject.pull #This should cause one pull that is immediately scheduled
      mutex.synchronize { pulled_condition.wait(mutex, 3) }
      expect(@pull_count).to eql 1

      #Those three below should cause just one pull
      mutex.synchronize {
        logger.debug 'Doing three pull requests...'
        subject.pull #This one will cause one pull
        subject.pull #this one should schedule single pull
        subject.pull #this one should schedule single pull
        subject.pull #this one should schedule single pull
        logger.debug 'Signalling multiple pull condition...'
        pulled_multiple_condition.signal
      }
      logger.debug 'Waiting for pulled condition...'
      pulled_multiple_condition.signal
      mutex.synchronize { pulled_condition.wait(mutex, 3) }
      pulled_multiple_condition.signal
      mutex.synchronize { pulled_condition.wait(mutex, 3) }
      expect(@pull_count).to eql 3
    end
  end
end