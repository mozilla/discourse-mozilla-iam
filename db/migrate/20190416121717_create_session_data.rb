class CreateSessionData < ActiveRecord::Migration[5.0]
  def change
    create_table :mozilla_iam_session_data do |t|
      t.integer :user_auth_token_id, null: false
      t.datetime :last_refresh
      t.string :aal
    end
  end
end
