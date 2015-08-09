class AddAttachmentContentToScripts < ActiveRecord::Migration
  def self.up
    change_table :scripts do |t|
      t.attachment :content
    end
  end

  def self.down
    remove_attachment :scripts, :content
  end
end
