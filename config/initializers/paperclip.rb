Paperclip::Attachment.default_options[:s3_host_name] = 's3-us-west-1.amazonaws.com'
Paperclip.options[:content_type_mappings] = {
  :coffee => "text/plain"
}
