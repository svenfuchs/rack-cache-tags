require "#{File.dirname(__FILE__)}/test_setup"

describe 'Rack::Cache::Tags' do
  before(:each) { setup_cache_context }
  after(:each)  { teardown_cache_context }

  it "writes tags for a key on :store" do
    respond_with 200, { 'X-Cache-Tags' => 'page-1,user-2', 'Cache-Control' => 'public, max-age=10000' }, 'body'

    response = get '/'
    tagstore.by_key.should == { 'http://example.org/' => ['page-1', 'user-2'] }
    tagstore.by_tag.should == { 'page-1' => ['http://example.org/'], 'user-2' => ['http://example.org/'] }
  end

  it "deletes tags for a key on :purge" do
    respond_with 200, { 'Cache-Control' => 'public, max-age=10000' }, 'body'
    respond_with 200, { 'Cache-Control' => 'public, max-age=500' }, 'body' do |req, res|
      case req.path
      when '/'
        res.headers['X-Cache-Tags'] = ['page-1,user-2']
      when '/users/2'
        res.headers['X-Cache-Purge-Tags'] = 'user-2'
      end
    end

    get '/'
    tagstore.by_key['http://example.org/'].should.include 'user-2'
    cache.trace.should.include :store

    get '/'
    cache.trace.should.include :fresh

    post '/users/2'
    tagstore.by_key['http://example.org/'].should.be.nil

    get '/'
    cache.trace.should.include :miss
  end

  def tagstore
    cache.send(:tagstore)
  end
end