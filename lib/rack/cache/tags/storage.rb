Rack::Cache::Storage.class_eval do
  alias :clear_without_tagstore :clear
  def clear
    @tagstores.clear
    clear_without_tagstore
  end

  def resolve_tagstore_uri(uri)
    @tagstores ||= {}
    @tagstores[uri.to_s] ||= create_store(Rack::Cache::Tags::TagStore, uri)
  end
end