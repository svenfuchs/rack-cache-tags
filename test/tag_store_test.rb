require File.expand_path("#{File.dirname(__FILE__)}/test_setup")

describe 'Rack::Cache::Tags::Tagstore' do
  describe 'Heap' do
    before(:each) do
      @store = Rack::Cache::Tags::TagStore::Heap.new
    end

    it "can be resolved from an uri" do
      tag_store = Rack::Cache::Storage.new.resolve_tagstore_uri('heap:/')
      tag_store.should.be.kind_of Rack::Cache::Tags::TagStore::Heap
    end

    it "writes to both read_key and read_tag" do
      @store.store('1234', 'tag-1,tag-2')

      @store.read_key('1234').should  == ['tag-1', 'tag-2']
      @store.read_tag('tag-1').should == ['1234']
      @store.read_tag('tag-2').should == ['1234']
      @store.read_tag('tag-3').should == []

      @store.store('5678', 'tag-1,tag-3')

      @store.read_key('1234').should  == ['tag-1', 'tag-2']
      @store.read_key('5678').should  == ['tag-1', 'tag-3']
      @store.read_tag('tag-1').should == ['1234', '5678']
      @store.read_tag('tag-2').should == ['1234']
      @store.read_tag('tag-3').should == ['5678']
    end

    it "purges from both read_key and read_tag" do
      @store.store('1234', 'tag-1,tag-2')
      @store.store('5678', 'tag-1,tag-3')

      @store.purge('1234')

      @store.read_key('1234').should  == []
      @store.read_key('5678').should  == ['tag-1', 'tag-3']
      @store.read_tag('tag-1').should == ['5678']
      @store.read_tag('tag-2').should == []
      @store.read_tag('tag-3').should == ['5678']
    end
  end

  describe 'File' do
    before(:each) do
      uri = URI.parse("file://#{TMP_DIR}/tagstore")
      @store = Rack::Cache::Tags::TagStore::Disk.resolve(uri)
    end

    after(:each) do
      FileUtils.rm_r(TMP_DIR) rescue Errno::ENOENT
    end

    it "can be resolved from an uri" do
      tag_store = Rack::Cache::Storage.new.resolve_tagstore_uri("file://#{TMP_DIR}/tagstore")
      tag_store.should.be.kind_of Rack::Cache::Tags::TagStore::Disk
    end

    it "writes to both read_key and read_tag" do
      @store.store('1234', 'tag-1,tag-2')

      @store.read_key('1234').should  == ['tag-1', 'tag-2']
      @store.read_tag('tag-1').should == ['1234']
      @store.read_tag('tag-2').should == ['1234']
      @store.read_tag('tag-3').should == []

      @store.store('5678', 'tag-1,tag-3')

      @store.read_key('1234').should  == ['tag-1', 'tag-2']
      @store.read_key('5678').should  == ['tag-1', 'tag-3']
      @store.read_tag('tag-1').should == ['1234', '5678']
      @store.read_tag('tag-2').should == ['1234']
      @store.read_tag('tag-3').should == ['5678']
    end

    it "purges from both read_key and read_tag" do
      @store.store('1234', 'tag-1,tag-2')
      @store.store('5678', 'tag-1,tag-3')

      @store.purge('1234')

      @store.read_key('1234').should  == []
      @store.read_key('5678').should  == ['tag-1', 'tag-3']
      @store.read_tag('tag-1').should == ['5678']
      @store.read_tag('tag-2').should == []
      @store.read_tag('tag-3').should == ['5678']
    end
  end
end