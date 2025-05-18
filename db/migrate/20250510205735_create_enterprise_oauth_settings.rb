class CreateEnterpriseOauthSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :enterprise_oauth_settings do |t|
      t.string :name, null: false
      t.string :domain, null: false
      t.string :provider, null: false
      t.string :client_id, null: false
      t.string :client_secret, null: false # Consider Rails encrypted credentials for production
      t.string :tenant_id # Nullable, specific to Azure/Entra ID
      t.string :hd # Nullable, specific to Google Workspace
      t.string :scopes # Nullable, for custom scopes

      t.timestamps
    end
    add_index :enterprise_oauth_settings, :domain, unique: true
  end
end
