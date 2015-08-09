json.array!(@scripts) do |script|
  json.extract! script, :id, :title, :description, :user_id
  json.url script_url(script, format: :json)
end
