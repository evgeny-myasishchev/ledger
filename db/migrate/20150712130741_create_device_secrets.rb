class CreateDeviceSecrets < ActiveRecord::Migration
  def change
    create_table :device_secrets do |t|
      t.references :user, index: true, null: false
      t.string :name, null: false
      t.string :device_id, null: false
      t.binary :secret, null: false

      t.timestamps null: false
    end
    add_index :device_secrets, :device_id, unique: true
  end
end
