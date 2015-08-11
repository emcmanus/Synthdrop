class AddLanguageToScript < ActiveRecord::Migration
  def change
    add_column :scripts, :language, :string, null: false, default: 'coffeescript'
  end
end
