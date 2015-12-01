namespace :es3_migrate do
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