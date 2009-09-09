require "#{File.dirname(__FILE__)}/test_setup"

describe 'Rack::Cache::Tags::Tagstore' do
  before(:each) do 
    @store = Rack::Cache::Tags::TagStore::Heap.new
  end
  
  it "can be resolved from an uri" do
    tag_store = Rack::Cache::Storage.new.resolve_tagstore_uri('heap:/')
    tag_store.should.be.kind_of Rack::Cache::Tags::TagStore::Heap
  end

  it "writes to both by_key and by_tag" do
    @store.store('1234', 'tag-1,tag-2')

    @store.by_key['1234'].should  == ['tag-1', 'tag-2']
    @store.by_tag['tag-1'].should == ['1234']
    @store.by_tag['tag-2'].should == ['1234']
    @store.by_tag['tag-3'].should == nil

    @store.store('5678', 'tag-1,tag-3')
    
    @store.by_key['1234'].should  == ['tag-1', 'tag-2']
    @store.by_key['5678'].should  == ['tag-1', 'tag-3']
    @store.by_tag['tag-1'].should == ['1234', '5678']
    @store.by_tag['tag-2'].should == ['1234']
    @store.by_tag['tag-3'].should == ['5678']
  end
  
  it "purges from both by_key and by_tag" do
    @store.store('1234', 'tag-1,tag-2')
    @store.store('5678', 'tag-1,tag-3')
    
    @store.purge('1234')
    
    @store.by_key['1234'].should  == nil
    @store.by_key['5678'].should  == ['tag-1', 'tag-3']
    @store.by_tag['tag-1'].should == ['5678']
    @store.by_tag['tag-2'].should == nil
    @store.by_tag['tag-3'].should == ['5678']
  end
  
end