class CreateProjectionsLedgers < ActiveRecord::Migration
  def change
    create_table :projections_ledgers do |t|
      t.string :aggregate_id, null: false
      t.integer :owner_user_id, null: false
      t.string :shared_with_user_ids
      t.string :name, null: false
    end
    add_index :projections_ledgers, :aggregate_id, unique: true
  end
end
