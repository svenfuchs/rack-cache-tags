Rack::Cache::MetaStore::Heap.class_eval do
  def store(request, response, entity_store)
    key = super

    tags = response.headers[Rack::Cache::TAGS_HEADER]
    tagstore(request).store(key, tags) if tags
    
    key
  end
  
  def tagstore(request)
    uri = request.env['rack-cache.tagstore']
    storage.resolve_tagstore_uri(uri)
  end

  def storage
    Rack::Cache::Storage.instance
  end
end
