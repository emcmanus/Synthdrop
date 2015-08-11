class AddKeyboardToUser < ActiveRecord::Migration
  def change
    add_column :users, :keyboard, :string, null: false, default: 'default'
  end
end
