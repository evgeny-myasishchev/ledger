class AddAuthorizedUserIdsToLedger < ActiveRecord::Migration
  def change
    add_column :projections_ledgers, :authorized_user_ids, :string
    remove_column :projections_ledgers, :shared_with_user_ids
  end
end
