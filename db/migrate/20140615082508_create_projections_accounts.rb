class CreateProjectionsAccounts < ActiveRecord::Migration
  def change
    create_table :projections_accounts do |t|
      t.string :ledger_id, null: false
      t.string :aggregate_id, null: false
      t.string :currency_code, null: false
      t.string :name, null: false
      t.integer :balance, null: false
    end
    add_index :projections_accounts, :ledger_id
    add_index :projections_accounts, :aggregate_id
  end
end
