namespace :es do
  desc 'Export commits'
  task :export_commits, [:path] => :environment do |_, a|
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
        f.write YAML.dump({
          stream_id: commit.stream_id,
          commit_id: commit.commit_id,
          commit_sequence: commit.commit_sequence,
          stream_revision: commit.stream_revision,
          commit_timestamp: commit.commit_timestamp,
          events: commit.events.map { |e|  
            e.body
          },
          headers: commit.headers
        })
      end
    end
  end
end