class CreateCategories < ActiveRecord::Migration
  def change
    create_table :projections_categories do |t|
      t.string :ledger_id, null: false
      t.integer :category_id, null: false
      t.integer :display_order, null: false
      t.string :name, null: false
      t.string :authorized_user_ids, null: false
    end
    add_index :projections_categories, [:ledger_id, :category_id], unique: true
  end
end
