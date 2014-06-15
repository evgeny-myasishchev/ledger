class CreateProjectionsAccounts < ActiveRecord::Migration
  def change
    create_table :projections_accounts do |t|
      t.string :ledger_id
      t.string :aggregate_id
      t.integer :currency_id
      t.string :name
      t.integer :balance

      t.timestamps
    end
    add_index :projections_accounts, :ledger_id
    add_index :projections_accounts, :aggregate_id
  end
end
