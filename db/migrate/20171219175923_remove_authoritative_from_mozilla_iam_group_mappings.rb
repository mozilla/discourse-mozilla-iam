class RemoveAuthoritativeFromMozillaIAMGroupMappings < ActiveRecord::Migration[5.1]
  def change
    remove_column :mozilla_iam_group_mappings, :authoritative, :boolean
  end
end
