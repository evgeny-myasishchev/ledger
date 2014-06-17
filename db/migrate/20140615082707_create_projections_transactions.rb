class CreateProjectionsTransactions < ActiveRecord::Migration
  def change
    create_table :projections_transactions do |t|
      t.string :transaction_id, null: false
      t.string :account_id, null: false
      t.integer :type_id, null: false
      t.integer :ammount, null: false
      t.integer :balance, null: false
      t.string :tag_ids
      t.text :comment
      t.datetime :date
    end
    add_index :projections_transactions, :transaction_id
    add_index :projections_transactions, :account_id
  end
end
