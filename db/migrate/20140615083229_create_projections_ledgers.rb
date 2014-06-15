class CreateProjectionsLedgers < ActiveRecord::Migration
  def change
    create_table :projections_ledgers do |t|
      t.string :aggregate_id
      t.integer :owner_user_id
      t.string :shared_with_user_ids
      t.string :name

      t.timestamps
    end
    add_index :projections_ledgers, :aggregate_id
  end
end
