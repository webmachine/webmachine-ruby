$:.push File.expand_path("../lib", __FILE__)
require 'webmachine'

class Constantized < Webmachine::Resource
  HELLO_WORLD = "Hello World".freeze
  ALLOWED_METHODS = [Webmachine::GET_METHOD].freeze
  CONTENT_TYPES_PROVIDED = [[Webmachine::TEXT_HTML, :to_html]].freeze

  def allowed_methods
    ALLOWED_METHODS
  end

  def content_types_provided
    CONTENT_TYPES_PROVIDED
  end

  def to_html
    HELLO_WORLD
  end
end

Webmachine.application.routes do
  add ['constantized'], Constantized
end

require 'webmachine/test'
session = Webmachine::Test::Session.new(Webmachine.application)

require 'memory_profiler'
report = MemoryProfiler.report do
  session.get('/constantized')
end

report.pretty_print

