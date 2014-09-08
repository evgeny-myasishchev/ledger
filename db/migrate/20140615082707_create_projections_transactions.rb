class CreateProjectionsTransactions < ActiveRecord::Migration
  def change
    create_table :projections_transactions do |t|
      t.string :transaction_id, null: false
      t.string :account_id, null: false
      t.integer :type_id, null: false
      t.integer :amount, null: false
      t.string :tag_ids
      t.text :comment
      t.datetime :date
      
      # Stuff related to transfers
      t.boolean :is_transfer, null: false, default: false
      t.string :sending_account_id, null: true, default: nil
      t.string :sending_transaction_id, null: true, default: nil
      t.string :receiving_account_id, null: true, default: nil
      t.string :receiving_transaction_id, null: true, default: nil
    end
    add_index :projections_transactions, :transaction_id, unique: true
    add_index :projections_transactions, :account_id
  end
end
