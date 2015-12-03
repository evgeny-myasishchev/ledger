class AddIsPendingToTransactions < ActiveRecord::Migration
  def change
    add_column :projections_transactions, :is_pending, :boolean, null: false, default: false
  end
end
