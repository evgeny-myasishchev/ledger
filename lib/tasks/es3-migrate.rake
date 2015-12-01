namespace :es3_migrate do
  task :rename_es_table do
    require 'log_factory'
    app = Rails.application
    logger = LogFactory.configure(app.config)
    es_db_config = app.config.database_configuration['event-store']
    db = Sequel.connect es_db_config
    db.loggers << logger

    logger.info 'Renaming initial es table to v3...'
    db.rename_table :'event-store-commits', :'event-store-commits-v3'
  end

  task :import_v3_commits, [:path] => :environment do |_, a|
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
end