class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_many :scripts

  validates :keyboard, inclusion: { in: %w( vim default ) }

  def keyboard=(value)
    write_attribute :keyboard, value.downcase
  end
end
