# test setup largely stolen from Ryan Tomayko's rack-cache

require 'pp'

begin
  require 'test/spec'
rescue LoadError => boom
  require 'rubygems' rescue nil
  require 'test/spec'
end

# Setup the load path ..
$: << File.dirname(File.dirname(__FILE__)) + '/../rack-cache/lib'
$: << File.dirname(File.dirname(__FILE__)) + '/../rack-cache-purge/lib'
$: << File.dirname(File.dirname(__FILE__)) + '/lib'
$: << File.dirname(__FILE__)

require 'rack/cache'
require 'rack/cache/purge'
require 'rack/cache/tags'

# Methods for constructing downstream applications / response
# generators.
module CacheContextHelpers
  attr_reader :app, :cache, :tags

  def setup_cache_context
    # holds each Rack::Cache::Context
    @app = nil

    # each time a request is made, a clone of @cache_template is used
    # and appended to @caches.
    @cache_template = nil
    @cache = nil
    @caches = []
    @errors = StringIO.new
    @cache_config = nil

    @called = false
    @request = nil
    @response = nil
    @responses = []

    @storage = Rack::Cache::Storage.instance
  end

  def teardown_cache_context
    @app, @cache_template, @cache, @caches, @called,
    @request, @response, @responses, @cache_config = nil
    @storage.clear
  end

  # A basic response with 200 status code and a tiny body.
  def respond_with(status=200, headers={}, body=['Hello World'])
    called = false
    @app = lambda do |env|
      called = true
      response = Rack::Response.new(body, status, headers)
      request = Rack::Request.new(env)
      yield request, response if block_given?
      response.finish
    end
    @app.meta_def(:called?) { called }
    @app.meta_def(:reset!) { called = false }
    @app
  end

  def cache_config(&block)
    @cache_config = block
  end

  def request(method, uri = '/', env = {})
    fail 'response not specified (use respond_with)' if @app.nil?
    @app.reset! if @app.respond_to?(:reset!)

    @tags    = Rack::Cache::Tags.new(@app)
    @purge   = Rack::Cache::Purge.new(@tags, :allow_http_purge => true)
    @cache   = Rack::Cache::Context.new(@purge, :tagstore => 'heap:/', &@cache_config)
    @request = Rack::MockRequest.new(@cache)

    env = { 'rack.run_once' => true }.merge(env)

    @response = @request.request(method.to_s.upcase, uri, env)
    @responses << @response
    @response
  end

  def get(stem, env={}, &b)
    request(:get, stem, env, &b)
  end

  def head(stem, env={}, &b)
    request(:head, stem, env, &b)
  end

  def post(*args, &b)
    request(:post, *args, &b)
  end
end

class Test::Unit::TestCase
  include CacheContextHelpers
end

# Metaid == a few simple metaclass helper
# (See http://whytheluckystiff.net/articles/seeingMetaclassesClearly.html.)
class Object
  # The hidden singleton lurks behind everyone
  def metaclass; class << self; self; end; end
  def meta_eval(&blk); metaclass.instance_eval(&blk); end
  # Adds methods to a metaclass
  def meta_def name, &blk
    meta_eval { define_method name, &blk }
  end
  # Defines an instance method within a class
  def class_def name, &blk
    class_eval { define_method name, &blk }
  end

  # True when the Object is neither false or nil.
  def truthy?
    !!self
  end
end
