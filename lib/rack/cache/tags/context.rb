module Rack::Cache::Tags
  class Context
    def initialize(backend, options = {})
      @backend = backend
      @options = options
      yield self if block_given?
    end

    def call(env)
      @env     = env
      request  = Rack::Cache::Request.new(env)
      response = Rack::Cache::Response.new(*@backend.call(env))
      
      tags = response.headers.delete(Rack::Cache::PURGE_TAGS_HEADER)
      if tags
        tags = Rack::Cache::Tags.normalize(tags)
        uris = tagged_uris(tags)
        response.headers[Rack::Cache::PURGE_HEADER] = uris.join("\n")
        
        purge_taggings(request, uris)
      end

      response.to_a
    end

    protected
      
      def tagged_uris(tags)
        tags.inject([]) { |uris, tag| uris + tagstore.by_tag[tag] }
      end
      
      def purge_taggings(request, uris)
        uris.each do |uri|
          key = Rack::Cache::Utils::Key.call(request, uri)
          tagstore.purge(key)
        end
      end
    
      def tagstore
        uri = @env['rack-cache.tagstore']
        storage.resolve_tagstore_uri(uri)
      end
    
      def storage
        Rack::Cache::Storage.instance
      end
  end
end