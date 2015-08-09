class Script < ActiveRecord::Base
  belongs_to :user
  has_attached_file :content, storage: :s3, s3_credentials: {
      access_key_id: ENV['S3_ACCESS_KEY_ID'],
      secret_access_key: ENV['S3_SECRET_ACCESS_KEY'],
      bucket: ENV['S3_BUCKET_NAME'],
    },
    url: "/scripts/:hash",
    hash_secret: ENV['S3_SUPER_SECRET_SECRET']
end
