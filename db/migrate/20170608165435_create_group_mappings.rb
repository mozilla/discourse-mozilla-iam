class CreateGroupMappings < ActiveRecord::Migration
  def change
    create_table :mozilla_iam_group_mappings do |t|
      t.integer :group_id, null: false
      t.string :iam_group_name, null: false
      t.boolean :authoritative
    end
  end
end
