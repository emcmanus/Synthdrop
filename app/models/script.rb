require('open-uri')
class Script < ActiveRecord::Base
  belongs_to :user

  validates :language,  presence: true, inclusion: { in: %w( javascript coffeescript ) }
  validates :user,      presence: true
  validates :title,     presence: true

  def language=(value)
    write_attribute :language, value.downcase
  end

  def extension
    case language
    when 'javascript'
      ".js"
    when 'coffeescript'
      ".coffee"
    else
      ".coffee"
    end
  end

  def content_url
    "https://s3-#{ENV['AWS_REGION']}.amazonaws.com/#{ENV['AWS_S3_BUCKET_NAME']}/#{aws_path}"
  end

  def content
    open(content_url).read if aws_id.present?
  end

  def content=(content)
    self.aws_id ||= SecureRandom.hex
    Aws::S3::Client.new.put_object( body: content, key: aws_path, acl: 'public-read', bucket: ENV['AWS_S3_BUCKET_NAME'] )
    content
  end

  private
    def aws_path
      "scripts/#{aws_id}"
    end
end
