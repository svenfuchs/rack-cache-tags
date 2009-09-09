require 'uri'

require 'rack/cache'
require 'rack/cache/storage'
require 'rack/cache/utils'

require 'rack/cache/tags/context'
require 'rack/cache/tags/storage'
require 'rack/cache/tags/tag_store'
require 'rack/cache/tags/meta_store'

module Rack::Cache
  TAGS_HEADER       = 'X-Cache-Tags'
  PURGE_TAGS_HEADER = 'X-Cache-Purge-Tags'

  Context.class_eval do
    option_accessor :tagstore

    def tagstore
      uri = options['rack-cache.tagstore']
      storage.resolve_tagstore_uri(uri)
    end
  end

  module Tags
    class << self
      def new(backend, options={}, &b)
        Context.new(backend, options, &b)
      end

      def normalize(tags)
        Array(tags).join(',').split(',').map { |tag| tag.strip }
      end
    end
  end
end