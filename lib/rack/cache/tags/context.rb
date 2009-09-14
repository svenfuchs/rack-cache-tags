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
      return response.to_a unless tags

      uris = tagged_uris(tags)
      if false && env.key?('rack-cache.purger')
        # TODO directly purge using uris?
      else
        set_purge_header(response, uris)
        purge_taggings(request, uris)
      end

      response.to_a
    end

    protected

      def tagged_uris(tags)
        tags = Rack::Cache::Tags.normalize(tags)
        tags.inject([]) { |uris, tag| uris + tagstore.read_tag(tag) }
      end

      def set_purge_header(response, uris)
        response.headers[Rack::Cache::PURGE_HEADER] = uris.join("\n")
      end

      def purge_taggings(request, uris)
        tagstore = self.tagstore
        keys = uris.map { |uri| Rack::Cache::Utils::Key.call(request, uri) }
        keys.each { |key| tagstore.purge(key) }
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