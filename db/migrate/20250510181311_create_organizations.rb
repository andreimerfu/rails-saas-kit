class CreateOrganizations < ActiveRecord::Migration[8.0]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :domain
      t.timestamps
      t.index :slug, unique: true
      t.index :domain, unique: true
    end
  end
end
