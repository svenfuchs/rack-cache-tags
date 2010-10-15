$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems'
require 'test/unit'
require 'fileutils'
require 'logger'
require 'bundler/setup'

require 'test_declarative'
require 'active_record'
require 'rack/mock'
require 'database_cleaner'
require 'rack_cache_tags'

log = '/tmp/rack_cache_tags.log'
FileUtils.touch(log) unless File.exists?(log)

ActiveRecord::Base.logger = Logger.new(log)
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define :version => 0 do
  create_table :cache_taggings, :force => true do |t|
    t.string :url
    t.string :tag
  end
end

DatabaseCleaner.strategy = :truncation

class Test::Unit::TestCase
  include Rack::Cache::Tags::Store

  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end

  attr_reader :app

  def create_tags(url, tags)
    tags.each { |tag| ActiveRecord::Tagging.create!(:url => url, :tag => tag) }
  end

  def respond_with(status, headers, body)
    @app = Rack::Cache::Tags.new(lambda { |env| [200, headers, ''] })
  end

  def get(url)
    app.call(env_for(url))
  end

  def env_for(*args)
    Rack::MockRequest.env_for(*args)
  end
end
