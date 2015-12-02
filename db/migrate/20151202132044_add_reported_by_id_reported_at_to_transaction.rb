class AddReportedByIdReportedAtToTransaction < ActiveRecord::Migration
  def change
    add_column :projections_transactions, :reported_by, :string
    add_column :projections_transactions, :reported_by_id, :integer
    add_column :projections_transactions, :reported_at, :datetime

    add_foreign_key :projections_transactions, :users, column: :reported_by_id, primary_key: :id
    add_index :projections_transactions, :reported_by_id
  end
end
