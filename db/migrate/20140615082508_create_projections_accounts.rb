class CreateProjectionsAccounts < ActiveRecord::Migration
  def change
    create_table :projections_accounts do |t|
      t.string :ledger_id, null: false
      t.string :aggregate_id, null: false
      t.integer :owner_user_id, null: false
      t.string :authorized_user_ids, null: false
      t.string :currency_code, null: false
      t.string :name, null: false
      t.integer :balance, null: false
      t.boolean :is_closed, null: false
    end
    add_index :projections_accounts, :ledger_id
    add_index :projections_accounts, :aggregate_id
  end
end
