class Script < ActiveRecord::Base
  belongs_to :user

  before_create do
  end
end
