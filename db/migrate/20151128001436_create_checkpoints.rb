class CreateCheckpoints < ActiveRecord::Migration
  def change
    create_table :checkpoints do |t|
      t.string :identifier, null: false
      t.integer :checkpoint_number, limit: 8, null: false
    end
    add_index :checkpoints, :identifier
  end
end
