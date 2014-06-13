class CreateProjectionsTags < ActiveRecord::Migration
  def change
    create_table :projections_tags do |t|
      t.string :ledger_id
      t.integer :tag_id
      t.string :name

      t.timestamps
    end
  end
end
