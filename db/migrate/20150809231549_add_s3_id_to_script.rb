class AddS3IdToScript < ActiveRecord::Migration
  def change
    add_column :scripts, :aws_id, :string, null: false
  end
end
