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
    app.event_store.persistence_engine.for_each_commit do |commit|
      commit_sequence+=1
      File.open(File.join(path, "commit-#{commit_sequence.to_s.rjust(5, '0')}.yaml"), 'w+') do |f|
        f.write dump_commit(YAML, commit)
      end
    end
  end

  desc 'Export stream'
  task :export_stream, [:stream_id, :path] => :environment do |_, a|
    raise ArgumentError, 'please provide path' unless a.path
    raise ArgumentError, 'please provide stream_id' unless a.stream_id
    path = Pathname.new(a.path)
    stream_id = a.stream_id
    app = Rails.application
    logger = app.config.logger
    logger.info "Exporting stream '#{stream_id}' to: #{path}"
    path.mkdir unless path.exist?
    stream = app.event_store.open_stream(stream_id)
    revision = 0
    stream.committed_events.each do |event|
      revision+=1
      File.open(File.join(path, "event-#{revision.to_s.rjust(5, '0')}.json"), 'w+') do |f|
        f.write JSON.pretty_generate(event)
      end
    end
  end

  private

  def dump_commit(dumper, commit)
    dumper.dump({
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