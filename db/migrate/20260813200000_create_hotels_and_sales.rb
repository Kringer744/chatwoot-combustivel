class CreateHotelsAndSales < ActiveRecord::Migration[7.1]
  def change
    create_table :hotels do |t|
      t.references :account, null: false, index: true
      t.string :name, null: false
      t.boolean :active, default: true, null: false
      t.timestamps
    end
    add_index :hotels, [:account_id, :name], unique: true

    create_table :hotel_agents do |t|
      t.references :hotel, null: false, index: true
      t.references :user, null: false, index: true
      t.timestamps
    end
    add_index :hotel_agents, [:hotel_id, :user_id], unique: true

    create_table :sales do |t|
      t.references :account, null: false, index: true
      t.references :conversation, null: false, index: true
      t.references :hotel, index: true
      t.references :user, index: true
      t.boolean :closed, default: false, null: false
      t.decimal :value, precision: 12, scale: 2, default: 0, null: false
      t.timestamps
    end
    add_index :sales, [:account_id, :closed]
  end
end
