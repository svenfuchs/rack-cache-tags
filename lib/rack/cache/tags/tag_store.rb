require 'rack/utils'
require 'digest/sha1'
require 'fileutils'
require 'core_ext/file_utils/rmdir_p'

module Rack::Cache::Tags
  class TagStore
    def read_key(key)
      key(key).read
    end

    def read_tag(tag)
      tag(tag).read
    end

    def store(key, tags)
      tags = Rack::Cache::Tags.normalize(tags)
      key(key, tags).store.each { |tag| read_tag(tag).add(key) }
    end

    def purge(key)
      read_key(key).purge.each { |tag| read_tag(tag).remove(key) }
    end

    public

      class Heap < TagStore
        def self.resolve(uri)
          new
        end

        def initialize
          @by_key, @by_tag = {}, {}
        end

        def key(key, tags = [])
          Collection.new(@by_key, :key, key, tags)
        end

        def tag(tag, keys = [])
          Collection.new(@by_tag, :tag, tag, keys)
        end

        class Collection < Array
          attr_reader :type, :owner, :hash

          def initialize(hash, type, owner, elements = [])
            @hash, @type, @owner = hash, type, owner
            super(elements) if elements
            compact
          end

          def add(element)
            return if element.nil? or include?(element)
            push(element)
            store
          end

          def remove(element)
            store if delete(element)
            self
          end

          def purge
            hash.delete(owner)
            self
          end

          def exist?
            hash.key?(owner)
          end

          def read
            replace(hash[owner] || [])
            self
          end

          def store
            return purge if empty?
            hash[owner] = self
          end
        end
      end

      HEAP = Heap
      MEM = HEAP

      class Disk < TagStore
        def self.resolve(uri)
          path = File.expand_path(uri.opaque || uri.path)
          new(path)
        end

        def initialize(root)
          @root = root
          FileUtils.mkdir_p root, :mode => 0755
        end

        def key(key, tags = [])
          Collection.new(@root, :key, key, tags)
        end

        def tag(tag, keys = [])
          Collection.new(@root, :tag, tag, keys)
        end

        class Collection < Array
          attr_reader :type, :owner, :root

          def initialize(root, type, owner, elements)
            @root, @type, @owner = root, type, owner
            super(elements) if elements
            compact
          end

          def add(element)
            return if element.nil? or include?(element)
            push(element)
            store
          end

          def remove(element)
            store if delete(element)
            self
          end

          def purge
            File.unlink(path) rescue Errno::ENOENT
            FileUtils.rmdir_p(File.dirname(path))
            self
          end

          def exist?
            File.exist?(path)
          end

          def read
            replace(read_file.split(','))
            self
          rescue Errno::ENOENT
            self
          end

          def store
            return purge if empty?

            FileUtils.mkdir_p(File.dirname(path), :mode => 0755)
            File.open(path, 'wb') { |f| f.write(join(',')) }
            self
          end

          protected

            def read_file
              File.open(path, 'rb') { |f| f.read }
            end

            def path
              File.join(root, "by_#{type}", spread(owner))
            end

            def digest(key)
              Digest::SHA1.hexdigest(key)
            end

            def spread(arg)
              arg = digest(arg)
              arg[2, 0] = '/'
              arg
            end
        end
      end

      DISK = Disk
      FILE = Disk
  end
end