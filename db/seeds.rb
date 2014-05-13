Rails.logger.info 'Seeding the database...'

require File.expand_path(File.join('..', 'currencies-loader.rb'), __FILE__)
CurrenciesLoader.load logger: Rails.logger