require File.expand_path('../test_helper', __FILE__)

class TagsTest < Test::Unit::TestCase
  include Rack::Cache::Tags::Store

  attr_reader :store

  def setup
    @store = Rack::Cache::Tags::Store::ActiveRecord.new
  end

  test 'stores tags for the current url' do
    respond_with 200, { Rack::Cache::Tags::TAGS_HEADER => %w(foo-1 bar-2) }, ''

    get('http://example.com/')
    actual = ActiveRecord::Tagging.all.map { |tagging| [tagging.url, tagging.tag] }
    assert_equal [%W(http://example.com/ foo-1), %W(http://example.com/ bar-2)], actual
  end

  test 'expands tags to urls for purge headers and deletes the tagging' do
    create_tags('http://example.com/foo', %w(foo-1 foo-2))
    create_tags('http://example.com/bar', %w(foo-1))
    create_tags('http://example.com/baz', %w(baz-1))

    respond_with 200, { Rack::Cache::Tags::PURGE_TAGS_HEADER => %w(foo-1) }, ''
    status, headers, body = get('http://example.com')

    actual = ActiveRecord::Tagging.all.map { |tagging| [tagging.url, tagging.tag] }
    assert_equal [%w(http://example.com/baz baz-1)], actual
    assert_equal %w(http://example.com/foo http://example.com/bar), headers[Rack::Cache::Purge::PURGE_HEADER]
  end

  test 'active_record store finds tags w/o methods' do
    tags = %w(foo-1 foo-2)
    create_tags('http://example.com/foo', tags)
    assert_equal tags, store.taggings_by_tags(tags).map(&:tag)
  end

  test 'active_record store finds tags w/ methods' do
    tags = %w(foo-1:title foo-1:body)
    create_tags('http://example.com/foo', tags)
    assert_equal tags, store.taggings_by_tags(%w(foo-1)).map(&:tag)
  end
end

