$:.push File.expand_path("../lib", __FILE__)
require 'webmachine'

class Constantized < Webmachine::Resource
  HELLO_WORLD = "Hello World".freeze
  ALLOWED_METHODS = ['GET'.freeze].freeze
  CONTENT_TYPES_PROVIDED = [['text/html'.freeze, :to_html].freeze].freeze

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
CONSTANTIZED = '/constantized'.freeze
require 'memory_profiler'
report = MemoryProfiler.report do
  5.times do
    session.get(CONSTANTIZED)
  end
end

report.pretty_print

