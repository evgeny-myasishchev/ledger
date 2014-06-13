class CreateProjectionsLedgers < ActiveRecord::Migration
  def change
    create_table :projections_ledgers do |t|
      t.string :aggregage_id
      t.integer :owner_user_id
      t.string :name

      t.timestamps
    end
    add_index :projections_ledgers, :aggregage_id, unique: true
    add_index :projections_ledgers, :owner_user_id
  end
end
