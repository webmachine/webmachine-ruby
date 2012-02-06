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

    # Initialize a Dispatcher instance
    def initialize
      @routes = []
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
      route = @routes.find {|r| r.match?(request) }
      if route
        resource = route.resource.new(request, response)
        route.apply(request)
        Webmachine::Decision::FSM.new(resource, request, response).run
      else
        Webmachine.render_error(404, request, response)
      end
    end

    # Resets, removing all routes. Useful for testing or reloading the
    # application.
    def reset
      @routes.clear
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
