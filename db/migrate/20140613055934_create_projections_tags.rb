class CreateProjectionsTags < ActiveRecord::Migration
  def change
    create_table :projections_tags do |t|
      t.string :ledger_id, null: false
      t.integer :tag_id, null: false
      t.string :name, null: false
    end
  end
end
