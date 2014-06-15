class CreateProjectionsTransactions < ActiveRecord::Migration
  def change
    create_table :projections_transactions do |t|
      t.string :transaction_id
      t.string :account_id
      t.integer :type_id
      t.integer :ammount
      t.integer :balance
      t.string :tag_ids
      t.text :comment

      t.timestamps
    end
    add_index :projections_transactions, :transaction_id
    add_index :projections_transactions, :account_id
  end
end
