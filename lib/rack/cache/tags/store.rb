module Rack
  module Cache
    class Tags
      module Store
        autoload :ActiveRecord, 'rack/cache/tags/store/active_record'
      end
    end
  end
end