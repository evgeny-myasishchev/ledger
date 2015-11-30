namespace :es do
  desc "Export commits"
  task :export_commits, [:path] => :environment do |t, a|    
    raise ArgumentError, 'please provide path' unless a.path
    path = Pathname.new(a.path)
    app = Rails.application
    logger = app.config.logger
    logger.info "Exporting commits to: #{path}"
    path.mkdir unless path.exist?

    commit_sequence = 0
    app.domain_context.event_store.persistence_engine.for_each_commit do |commit|
      commit_sequence+=1
      File.open(File.join(path, "commit-#{commit_sequence.to_s.rjust(5, '0')}.yaml"), 'w+') do |f|
        f.write YAML.dump(commit)
      end
    end

  end
end