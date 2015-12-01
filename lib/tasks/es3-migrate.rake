namespace :es3_migrate do

  desc '#1 - rename es table to es3'
  task :rename_es_table do
    require 'log_factory'
    app = Rails.application
    logger = LogFactory.configure(app.config)
    es_db_config = app.config.database_configuration['event-store']
    db = Sequel.connect es_db_config
    db.loggers << logger

    db.transaction do
      logger.info 'Renaming initial es table to v3...'
      db.rename_table :'event-store-commits', :'event-store-commits-v3'
      logger.info 'Dropping indexes to avoid conflicts'
      db.drop_index 'event-store-commits', [:stream_id, :commit_sequence]
      db.drop_index 'event-store-commits', [:stream_id, :stream_revision]
    end
  end

  desc '#2 - import es3 commits'
  task :import_commits, [:path] => :environment do |_, a|
    raise ArgumentError, 'please provide path' unless a.path
    path = Pathname.new(a.path).expand_path
    raise ArgumentError, "path not found: #{path}" unless path.exist?
    app = Rails.application
    logger = app.config.logger
    logger.info "Importing commits from: #{path}"
    Dir.chdir(path) do
      Dir.glob('*.yaml').sort.each do |file|
        yaml_doc = YAML.load(File.read(File.join(path, file)))
        commit = EventStore::Commit.new(yaml_doc)
        logger.info "Processing commit #{commit.commit_id}"
        app.event_store.persistence_engine.commit commit
      end
    end
  end

  desc '#3 - init checkpoints'
  task :init_checkpoints do
    require 'log_factory'
    app = Rails.application
    logger = LogFactory.configure(app.config)
    es_db = Sequel.connect app.config.database_configuration['event-store']
    es_db.loggers << logger

    db = Sequel.connect app.config.database_configuration[Rails.env]
    db.loggers << logger

    last_checkpoint_number = es_db[:'event-store-commits'].max(:checkpoint_number)

    logger.info "Last checkpoint number: #{last_checkpoint_number}. Initializing persistent checkpoints."
    db[:checkpoints].delete
    checkpoints = %w(Projections::Account::Projection
      Projections::Category::Projection
      Projections::Transaction::Projection
      Projections::PendingTransaction::Projection
      Projections::Ledger::Projection Projections::Tag::Projection)
    checkpoints.each do |checkpoint|
      db[:checkpoints].insert(identifier: checkpoint, checkpoint_number: last_checkpoint_number)
    end
  end
end