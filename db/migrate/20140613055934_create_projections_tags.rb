class CreateProjectionsTags < ActiveRecord::Migration
  def change
    create_table :projections_tags do |t|
      t.string :ledger_id, null: false
      t.integer :tag_id, null: false
      t.string :name, null: false
      t.string :authorized_user_ids, null: false
    end
    add_index :projections_tags, [:ledger_id, :tag_id], unique: true
  end
end
