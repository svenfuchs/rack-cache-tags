require File.expand_path("#{File.dirname(__FILE__)}/../test_setup")

require 'rubygems'
require 'action_controller'
require 'rack/cache/tags/rails/action_controller'

class Foo
  include MethodCallTracking
  def bar
    'YAY'
  end
  def cache_tag
    "foo-1"
  end
end

class FooController < ActionController::Base
  cache_tags :index, :track => { :@foo => :bar }
  def index
    @foo = Foo.new
    render :file => File.expand_path(File.dirname(__FILE__) + '/templates/index.html.erb')
  end
end

describe 'Rack::Cache::Tags::Rails::ActionController' do
  it "tracks references (method access) to objects assigned to the view" do
    get('/')
    references = @controller.reference_tracker.references

    assert_equal "200 OK", @response.status
    assert_equal 1, references.size
    assert_equal Foo, references.first[0].class
    assert_equal :bar, references.first[1]
  end
  
  it "adds an after_filter that adds cache-control, max-age and x-cache-tags headers" do
    get('/')
    assert_equal "foo-1", @response.headers[Rack::Cache::TAGS_HEADER]
  end

  it "sends cache-control, max-age and x-cache-tags headers" do
    assert FooController.filter_chain.select { |f| f.type == :after }
  end

  def get(path)
    @request = ActionController::Request.new(
      "REQUEST_METHOD" => "GET",
      "REQUEST_URI"    => path,
      "rack.input"     => "",
      "action_controller.request.path_parameters" => { :action => 'index' }
    )
    @response = ActionController::Response.new
    @controller = FooController.new
    @controller.process(@request, @response)
  end
end