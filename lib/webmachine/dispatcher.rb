require 'forwardable'
require 'webmachine/decision'
require 'webmachine/dispatcher/route'

module Webmachine
  # Handles dispatching incoming requests to the proper registered
  # resources and initializing the decision logic.
  class Dispatcher
    # @return [Array<Route>] the list of routes that will be
    #   dispatched to
    # @see #add_route
    attr_reader :routes

    # The creator for resources used to process requests.
    # Must respond to call(route, request, response) and return
    # a newly created resource instance.
    attr_accessor :resource_creator

    # Initialize a Dispatcher instance
    # @param resource_creator Invoked to create resource instances.
    def initialize(resource_creator = method(:create_resource))
      @routes = []
      @resource_creator = resource_creator
    end

    # Adds a route to the dispatch list. Routes will be matched in the
    # order they are added.
    # @see Route#new
    def add_route(*args, &block)
      route = Route.new(*args, &block)
      @routes << route
      route
    end
    alias :add :add_route

    # Dispatches a request to the appropriate {Resource} in the
    # dispatch list. If a matching resource is not found, a "404 Not
    # Found" will be rendered.
    # @param [Request] request the request object
    # @param [Response] response the response object
    def dispatch(request, response)
      if resource = find_resource(request, response)
        Webmachine::Events.instrument('wm.dispatch') do |payload|
          Webmachine::Decision::FSM.new(resource, request, response).run

          payload[:resource] = resource.class.name
          payload[:request] = request.dup
          payload[:code] = response.code
        end
      else
        Webmachine.render_error(404, request, response)
      end
    end

    # Resets, removing all routes. Useful for testing or reloading the
    # application.
    def reset
      @routes.clear
    end

    # Find the first resource that matches an incoming request
    # @param [Request] request the request to match
    # @param [Response] response the response for the resource
    def find_resource(request, response)
      if route = find_route(request)
        prepare_resource(route, request, response)
      end
    end

    # Find the first route that matches an incoming request
    # @param [Request] request the request to match
    def find_route(request)
      @routes.find {|r| r.match?(request) }
    end

    private
    def prepare_resource(route, request, response)
      route.apply(request)
      @resource_creator.call(route, request, response)
    end

    def create_resource(route, request, response)
      route.resource.new(request, response)
    end
  end

  # Evaluates the passed block in the context of
  # {Webmachine::Dispatcher} for use in adding a number of routes at
  # once.
  # @return [Webmachine] self
  # @see Webmachine::Dispatcher#add_route
  def self.routes(&block)
    application.routes(&block)
    self
  end
end # module Webmachine
