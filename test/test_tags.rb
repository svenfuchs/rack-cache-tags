require File.expand_path('../test_helper', __FILE__)

class TagsTest < Test::Unit::TestCase
  include Rack::Cache::Tags::Store

  test 'stores tags for the current url' do
    url = 'http://example.com/foo'
    headers = { Rack::Cache::Tags::TAGS_HEADER => %w(foo-1 bar-2) }
    tags = Rack::Cache::Tags.new(lambda { |env| [200, headers, ''] })

    tags.call(env_for(url))
    actual = ActiveRecord::Tagging.all.map { |tagging| [tagging.url, tagging.tag] }
    assert_equal [%W(#{url} foo-1), %W(#{url} bar-2)], actual
  end

  test 'expands tags to urls for purge headers and deletes the tagging' do
    create_tags('http://example.com/foo', %w(foo-1 foo-2))
    create_tags('http://example.com/bar', %w(foo-1))
    create_tags('http://example.com/baz', %w(baz-1))

    headers = { Rack::Cache::Tags::PURGE_TAGS_HEADER => %w(foo-1) }
    tags = Rack::Cache::Tags.new(lambda { |env| [200, headers, ''] })

    status, headers, body = tags.call(env_for('http://example.com'))

    actual = ActiveRecord::Tagging.all.map { |tagging| [tagging.url, tagging.tag] }
    assert_equal [%w(http://example.com/baz baz-1)], actual

    assert_equal %w(http://example.com/foo http://example.com/bar), headers[Rack::Cache::Tags::PURGE_HEADER]
  end
  
  protected

    def create_tags(url, tags)
      tags.each { |tag| ActiveRecord::Tagging.create!(:url => url, :tag => tag) }
    end

    def env_for(*args)
      Rack::MockRequest.env_for(*args)
    end
end