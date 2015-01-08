class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name

      # email/password
      t.string :email
      t.string :password_hash

      # 'remember me' support
      t.string :remember_token
      t.datetime :remember_token_expires_at

      # reset password support
      t.string :reset_token
      t.datetime :reset_token_expires_at

      t.timestamps
    end

    add_index :users, :email, :unique => true
    add_index :users, :remember_token
    add_index :users, :reset_token
  end
end
