class AddPendingBalanceToAccounts < ActiveRecord::Migration
  def change
    add_column :projections_accounts, :pending_balance, :integer, null: false, default: 0
  end
end
