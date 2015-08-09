require('open-uri')
class Script < ActiveRecord::Base
  belongs_to :user

  def content_url
    "#{ENV['S3_URL_PREFIX']}#{ENV['S3_BUCKET_NAME']}#{aws_path}"
  end

  def content
    open(content_url).read
  end

  def content=(content)
    aws_id ||= SecureRandom.hex
    AWS::S3::Base.establish_connection!(
      access_key_id:        ENV['S3_ACCESS_KEY_ID'],
      secret_access_key:    ENV['S3_SECRET_ACCESS_KEY'],
    )
    AWS::S3::S3Object.store(aws_path, content, ENV['S3_BUCKET_NAME'], content_type: 'text/plain')
  end

  private
    def aws_path
      "/scripts/#{aws_id}"
    end
end
