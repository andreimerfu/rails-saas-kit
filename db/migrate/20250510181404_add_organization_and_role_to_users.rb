class AddOrganizationAndRoleToUsers < ActiveRecord::Migration[8.0]
  def up
    # Add organization_id as nullable first
    add_reference :users, :organization, null: true, foreign_key: true
    add_column :users, :role, :integer, null: false, default: 0  # 0 = member
    add_index :users, :role

    # Create default organization for existing users
    default_org = Organization.create!(
      name: 'Default Organization',
      slug: 'default-organization'
    )

    # Assign all existing users to the default organization
    User.update_all(organization_id: default_org.id)

    # Now make organization_id non-nullable
    change_column_null :users, :organization_id, false
  end

  def down
    remove_reference :users, :organization
    remove_column :users, :role
  end
end
