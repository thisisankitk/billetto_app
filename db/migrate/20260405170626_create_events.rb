class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :external_id
      t.string :title
      t.text :description
      t.datetime :starts_at
      t.datetime :ends_at
      t.string :image_url
      t.string :city
      t.string :venue_name
      t.integer :price_cents
      t.string :currency
      t.string :organiser_name
      t.string :url
      t.jsonb :raw_payload

      t.timestamps
    end
    add_index :events, :external_id, unique: true
  end
end
