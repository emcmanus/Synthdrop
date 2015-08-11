class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_many :scripts

  validates :keyboard,  inclusion: { in: %w( default vim emacs ) }
  validates :rc,        length: { minimum: 0, maximum: 5_000 }

  def keyboard=(value)
    write_attribute :keyboard, value.downcase
  end
end
