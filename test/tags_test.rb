require File.expand_path("#{File.dirname(__FILE__)}/test_setup")

# When the downstream app sends an X-Cache-Tag header *and* the response is
# cacheable store taggings for the cache entry
#
# When the downstream app sends an X-Cache-Purge-Tags header:
#
# * remove the headers
# * lookup any tagged URIs
# * set them as X-Cache-Purge headers
#
# When a cache entry is purged also purge its taggings.

describe 'Rack::Cache::Tags' do
  before(:each) { setup_cache_context }
  after(:each)  { teardown_cache_context }

  configs = [
    {
      'metastore'   => 'heap:/',
      'entitystore' => 'heap:/',
      'tagstore'    => 'heap:/'
    },
    {
      'metastore'   => "file://#{TMP_DIR}/metastore",
      'entitystore' => "file://#{TMP_DIR}/entitystore",
      'tagstore'    => "file://#{TMP_DIR}/tagstore"
    }
  ]

  configs.each do |config|
    it "writes taggings for an entry on :store (#{config[config.keys.first]})" do
      cache_config do |cache|
        config.each { |key, value| cache.options["rack-cache.#{key}"] = value }
      end
      respond_with 200, { 'X-Cache-Tags' => 'page-1,user-2', 'Cache-Control' => 'public, max-age=10000' }, 'body'

      response = get '/'
      tagstore.read_key('http://example.org/').should  == ['page-1', 'user-2']
      tagstore.read_tag('page-1').should  == ['http://example.org/']
      tagstore.read_tag('user-2').should  == ['http://example.org/']
    end

    # TODO test all three purging methods!
    it "deletes taggings for a key on :purge (using HTTP PURGE)" do
      respond_with 200, { 'Cache-Control' => 'public, max-age=500' }, 'body' do |req, res|
        case req.path
        when '/'
          res.headers['X-Cache-Tags'] = ['page-1,user-2']
        when '/users/2'
          subrequest(:purge, '/')
        end
      end

      it_purges_cache_entry_including_tags
    end

    it "deletes taggings for a key on :purge (using tag headers)" do
      respond_with 200, { 'Cache-Control' => 'public, max-age=500' }, 'body' do |req, res|
        case req.path
        when '/'
          res.headers['X-Cache-Tags'] = ['page-1,user-2']
        when '/users/2'
          res.headers['X-Cache-Purge-Tags'] = 'user-2'
        end
      end

      it_purges_cache_entry_including_tags
    end

    it "deletes taggings for a key on :purge (using manual purge)" do
      respond_with 200, { 'Cache-Control' => 'public, max-age=500' }, 'body' do |req, res|
        case req.path
        when '/'
          res.headers['X-Cache-Tags'] = ['page-1,user-2']
        when '/users/2'
          req.env['rack-cache.purger'].purge('http://example.org/')
        end
      end

      it_purges_cache_entry_including_tags
    end
  end

  def it_purges_cache_entry_including_tags
    get '/'
    tagstore.read_key('http://example.org/').should.include 'user-2'
    cache.trace.should.include :store

    get '/'
    cache.trace.should.include :fresh

    post '/users/2'
    tagstore.read_key('http://example.org/').should == []

    get '/'
    cache.trace.should.include :miss
  end

  def subrequest(method, path)
    purge = Rack::Cache::Purge.new(nil, :allow_http_purge => true)
    app   = Rack::Cache::Context.new(purge, :tagstore => 'heap:/')
    app.call(
      "REQUEST_METHOD"  => method.to_s.upcase,
      "SERVER_NAME"     => "example.org",
      "SERVER_PORT"     => "80",
      "PATH_INFO"       => path,
      "rack.url_scheme" => "http",
      "rack.errors"     => StringIO.new
    )
  end

  def tagstore
    cache.send(:tagstore)
  end
end