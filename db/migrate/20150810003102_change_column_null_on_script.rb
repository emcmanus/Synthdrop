class ChangeColumnNullOnScript < ActiveRecord::Migration
  def change
    change_column_null :scripts, :aws_id, null: true
  end
end
