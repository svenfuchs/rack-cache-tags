module Rack
  module Cache
    module Tags
      module Purger
        def purge(arg)
          keys = super
          tagstore = self.tagstore
          keys.each { |key| tagstore.purge(key) }
        end

        def tagstore
          uri = context.env['rack-cache.tagstore']
          storage.resolve_tagstore_uri(uri)
        end
      end
    end
  end
end