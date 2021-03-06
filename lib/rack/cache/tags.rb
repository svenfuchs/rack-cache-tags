require 'rack/request'
require 'rack/cache/purge'

module Rack
  module Cache
    class Tags
      autoload :Store, 'rack/cache/tags/store'

      class << self
        def store
          @store ||= Store::ActiveRecord.new
        end

        def store=(store)
          @store ||= store
        end
      end

      PURGE_TAGS_HEADER = 'rack-cache.purge-tags'
      TAGS_HEADER       = 'rack-cache.tags'

      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body = app.call(env)
        store(Rack::Request.new(env).url, headers[TAGS_HEADER]) if status == 200 && headers.key?(TAGS_HEADER)
        purge(headers) if headers.key?(PURGE_TAGS_HEADER)
        [status, headers, body]
      end

      protected

        def store(*args)
          self.class.store.store(*args)
        end

        def purge(headers)
          urls = self.class.store.purge(headers[PURGE_TAGS_HEADER])
          headers[Purge::PURGE_HEADER] = urls unless urls.empty?
        end
    end
  end
end
