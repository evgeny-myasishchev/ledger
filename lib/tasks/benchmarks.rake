namespace :bm do
  task :get_snapshot, [:account_id] do |t, a|
    require 'benchmark'
    
    account_id = a.account_id
    raise 'Please provide account_id' unless account_id
    times = 10
    
    Rails.application.initialize!
    log = LogFactory.logger "ledger"
    
    # log.info 'Starting Snapshot.get (with ar) benchmark'
    # bm = Benchmark.measure {
    #   times.times do
    #     Snapshot.get account_id
    #   end
    # }
    # log.info "Snapshot.get (with ar): #{bm.real / times}"
    
    log.info 'Starting Snapshot.get (with sequel) benchmark'
    sequel_repo = Snapshot::SequelRepo.new Rails.application.config.database_configuration['snapshots']
    bm = Benchmark.measure {
      times.times do
        sequel_repo.get account_id
      end
    }
    log.info "Snapshot.get (with sequel): #{bm.real / times}"
  end
  
  task :account_get_by_id, [:with_snapshots] do |t, a|
    with_snapshots = a.with_snapshots == 'true' ? true : false
    LedgerBenchmarks.run Rails.application, with_snapshots: with_snapshots
  end

  class LedgerBenchmarks
    require 'benchmark'
    
    def self.run app, options = {}
      new(app, options).run
    end
    
    attr_reader :log
    
    def initialize(app, options)
      @options = options
      @context = bootstrap app, with_snapshots: @options[:with_snapshots] || false
      @write_repo = @context.repository_factory.create_repository
    end
    
    def run
      log.info "Starting account get_by_id benchmark test. Options: #{@options.to_json}"
      
      account_id = Domain::Account::AccountId.new 'account-1', 1
      initial_data = Domain::Account::InitialData.new 'account-1', 100000, Currency['UAH']
      account = Domain::Account.new
    
      bm = Benchmark.measure {
        account.create 'ledger-1', account_id, initial_data
        @write_repo.save account
      }
      log.info "Account created and saved: #{bm.real}"
    
      new_bm = bm_get_by_id
      4.times do
        report_transactions_and_bm number: 1
        bm_get_by_id original_bm_real: new_bm
      end
      
      report_transactions_and_bm number: 1
      bm_get_by_id original_bm_real: new_bm
      
      10.times do
        report_transactions_and_bm number: 50
        bm_get_by_id original_bm_real: new_bm
      
        report_transactions_and_bm number: 5
        bm_get_by_id original_bm_real: new_bm
      end
      
      log.info 'Done.'
    end
    
    private
      def bm_get_by_id original_bm_real: nil
        account = nil
        @context.repository_factory.create_repository.get_by_id Domain::Account, 'account-1' #warmup
        bm1 = Benchmark.measure { account = @context.repository_factory.create_repository.get_by_id Domain::Account, 'account-1' }
        bm2 = Benchmark.measure { account = @context.repository_factory.create_repository.get_by_id Domain::Account, 'account-1' }
        bm3 = Benchmark.measure { account = @context.repository_factory.create_repository.get_by_id Domain::Account, 'account-1' }
        
        bm_real = (bm1.real + bm2.real + bm3.real) / 3
        degradation = original_bm_real.nil? ? nil : (", degradation: " + ((bm_real  * 100) / original_bm_real - 100).round(2).to_s + "%")
        log.info "Account (version=#{account.version}) with '#{account.applied_events_number}' events loaded: #{bm_real.round(5)}#{degradation}"
        bm_real
      end
      
      def report_transactions_and_bm number: 0
        log.debug "Reporting #{number} transactions (saving each individually)..."
        repo = @context.repository_factory.create_repository
        account = repo.get_by_id Domain::Account, 'account-1'
        bm = Benchmark.measure {
          number.times do
            account.report_expense 100, DateTime.now, [], 'Benchmark test expense'
            repo.save account
          end
        }
        log.debug "#{number} transactions generated: #{bm.real}"
      end
    
      def bootstrap app, with_snapshots: false
        init_app_skiping_domain_context app
        log.debug "Bootstrapping domain context. with_snapshots: #{with_snapshots}"
        context = DomainContext.new do |c|
          c.with_database_configs app.config.database_configuration
          c.with_event_bus CommonDomain::EventBus.new
          if with_snapshots
            log.info 'Discarding snapshots...'
            Snapshot.delete_all
            c.with_snapshots Snapshot 
          end
          c.with_event_store
        end
        context.event_store.purge
        context
      end

      def init_app_skiping_domain_context app
        return if app.initialized?
        app.skip_domain_context = true
        app.initialize!
        @log = LogFactory.logger "ledger"
      end
  end
end