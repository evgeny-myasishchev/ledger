class CreateSnapshots < ActiveRecord::Migration
  def change
    create_table :snapshots do |t|
      t.string :aggregate_id, null: false
      t.integer :version, null: false
      t.binary :data, null: false
    end
    add_index :snapshots, :aggregate_id, unique: true
  end
end
