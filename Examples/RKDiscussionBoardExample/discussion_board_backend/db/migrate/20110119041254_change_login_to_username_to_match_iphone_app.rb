class ChangeLoginToUsernameToMatchIphoneApp < ActiveRecord::Migration
  def self.up
    rename_column :users, :login, :username
  end

  def self.down
    rename_column :users, :username, :login
  end
end
