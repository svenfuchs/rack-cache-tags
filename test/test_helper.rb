$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems'
require 'test/unit'
require 'test_declarative'
require 'fileutils'
require 'active_record'
require 'logger'
require 'rack/mock'
require 'database_cleaner'

require 'rack_cache_tags'

log = '/tmp/rack_cache_tags.log'
FileUtils.touch(log) unless File.exists?(log)

ActiveRecord::Base.logger = Logger.new(log)
ActiveRecord::LogSubscriber.attach_to(:active_record)
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
  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end
end