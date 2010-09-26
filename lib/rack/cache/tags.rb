require 'rack/request'

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

      TAGS_HEADER       = 'rack-cache.tags'
      PURGE_HEADER      = 'rack-cache.purge'
      PURGE_TAGS_HEADER = 'rack-cache.purge-tags'
      
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
          headers[PURGE_HEADER] = urls unless urls.empty?
          headers.delete(PURGE_TAGS_HEADER)
        end
    end
  end
end