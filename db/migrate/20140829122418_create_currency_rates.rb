class CreateCurrencyRates < ActiveRecord::Migration
  def change
    create_table :currency_rates do |t|
      t.string :from, null: false
      t.string :to, null: false
      t.float :rate, null: false

      t.timestamps
    end
    add_index :currency_rates, [:from, :to], unique: true
  end
end
