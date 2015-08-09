class CreateScripts < ActiveRecord::Migration
  def change
    create_table :scripts do |t|
      t.string :title
      t.text :description
      t.references :user, index: true

      t.timestamps null: false
    end
    add_foreign_key :scripts, :users
  end
end
