class CreateCurrencies < ActiveRecord::Migration
  def change
    create_table :currencies do |t|
      t.string :english_country_name, null: false
      t.string :english_name, null: false
      t.string :alpha_code, null: false
      t.integer :numeric_code, null: false
    end
    
    reversible do |dir|
      dir.up {
        require File.expand_path(File.join('..', '..', 'currencies-loader.rb'), __FILE__)
        CurrenciesLoader.load logger: Rails.logger
      }
    end
  end
end
