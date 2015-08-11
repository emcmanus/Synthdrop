class AddSynthdropRcToUser < ActiveRecord::Migration
  def change
    add_column :users, :rc, :text
  end
end
