require File.expand_path("#{File.dirname(__FILE__)}/test_setup")
require 'method_call_tracking'

class Template
  def initialize(locals)
    locals.each { |name, value| instance_variable_set(:"@#{name}", value) }
  end
end

class Foo
  include MethodCallTracking
  def self.bar; end
  attr_reader :attributes
  def initialize; @attributes = {}; end
  def bar; end
end

describe 'MethodCallTracking' do
  describe 'setup' do
    before(:each) do
      @foo = Foo.new
      @template = Template.new(:foo => @foo)
      @tracker = MethodCallTracking::Tracker.new
    end
    
    it "with an instance and method definition" do
      @tracker.track(@template, :@foo => :bar)
      @foo.bar
      assert_referenced @foo, :bar
    end
    
    it "with an instance and no method" do
      @tracker.track(@template, :@foo => nil)
      @foo.attributes[:bar]
      assert_referenced @foo
    end
    
    def assert_referenced(object, method = nil)
      assert @tracker.references.any? { |reference|
        reference[0] == object && reference[1] == method
      }, "should reference #{object.inspect}, #{method ? method.inspect : ''} but doesn't"
    end
  end
end
