# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'rack_cache_tags/version'

Gem::Specification.new do |s|
  s.name         = "rack-cache-tags"
  s.version      = RackCacheTags::VERSION
  s.authors      = ["Sven Fuchs"]
  s.email        = "svenfuchs@artweb-design.de"
  s.homepage     = "http://github.com/svenfuchs/rack-cache-tags"
  s.summary      = "[summary]"
  s.description  = "[description]"

  s.files        = Dir.glob("lib/**/**")
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'
  s.required_rubygems_version = '>= 1.3.6'
end
