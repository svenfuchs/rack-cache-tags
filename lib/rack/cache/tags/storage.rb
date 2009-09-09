Rack::Cache::Storage.class_eval do
  def resolve_tagstore_uri(uri)
    @tagstores ||= {}
    @tagstores[uri.to_s] ||= create_store(Rack::Cache::Tags::TagStore, uri)
  end
end