class CreateProjectionsAccounts < ActiveRecord::Migration
  def change
    create_table :projections_accounts do |t|
      t.string :ledger_id, null: false
      t.string :aggregate_id, null: false
      t.integer :sequential_number, null: false
      t.integer :owner_user_id, null: false
      t.string :authorized_user_ids, null: false
      t.integer :category_id, null: true
      t.string :currency_code, null: false
      t.string :name, null: false
      t.string :unit
      t.integer :balance, null: false
      t.boolean :is_closed, null: false
    end
    add_index :projections_accounts, :ledger_id
    add_index :projections_accounts, [:ledger_id, :sequential_number], unique: true
    add_index :projections_accounts, :aggregate_id, unique: true
  end
end
