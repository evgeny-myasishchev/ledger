class CreateProjectionsPendingTransactions < ActiveRecord::Migration
  def change
    create_table :projections_pending_transactions do |t|
      t.string :aggregate_id, null: false
      t.integer :user_id, null: false
      t.string :amount, null: false
      t.datetime :date
      t.string :tag_ids
      t.text :comment
      t.string :account_id
      t.integer :type_id, null: false
    end
    add_index :projections_pending_transactions, :aggregate_id, unique: true
    add_index :projections_pending_transactions, :user_id
  end
end
