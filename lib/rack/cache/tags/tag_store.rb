require 'fileutils'
require 'digest/sha1'
require 'rack/utils'

module Rack::Cache::Tags
  class TagStore
    def store(key, tags)
      tags = Rack::Cache::Tags.normalize(tags)
      write(key, tags)
    end
  
    def by_key(key)
      raise NotImplemented
    end

    def by_tag(tag)
      raise NotImplemented
    end

  protected

    def write(key, tags)
      raise NotImplemented
    end

    def purge(key)
      raise NotImplemented
    end

  public

    class Heap < TagStore
      def self.resolve(uri)
        new
      end
      
      def initialize
        @hash = { :by_key => {}, :by_tag => {} }
      end
      
      def by_key
        @hash[:by_key]
      end
      
      def by_tag
        @hash[:by_tag]
      end

      def purge(key)
        if tags = by_key[key]
          tags.each do |tag|
            next unless by_tag[tag]
            by_tag[tag].delete(key) 
            by_tag.delete(tag) if by_tag[tag].empty?
          end
        end
        
        by_key.delete(key)
        nil
      end

      def write(key, tags)
        by_key[key] = tags

        tags.each do |tag|
          by_tag[tag] ||= []
          by_tag[tag] << key unless by_tag[tag].include?(key)
        end
      end
    end

    HEAP = Heap
    MEM = HEAP
  end
end