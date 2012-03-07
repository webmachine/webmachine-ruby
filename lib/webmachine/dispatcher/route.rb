require 'webmachine/resource'
require 'webmachine/translation'

module Webmachine
  class Dispatcher
    # Pairs URIs with {Resource} classes in the {Dispatcher}. To
    # create routes, use {Dispatcher#add_route}.
    class Route
      # @return [Class] the resource this route will dispatch to, a
      #   subclass of {Resource}
      attr_reader :resource

      # @return [Array<String|Symbol>] the list of path segments
      #   used to define this route (see #initialize).
      attr_reader :path_spec

      # @return [Array<Proc>] the list of guard blocks used to define this
      #   route (see #initialize).
      attr_reader :guards

      # When used in a path specification, will match all remaining
      # segments
      MATCH_ALL = '*'.freeze

      # When used in a path specification, will match all remaining
      # segments if there is at least one
      MATCH_AT_LEAST_ONE = '+'.freeze

      # When used in a path specification, will match exactly one
      # remaining segment
      MATCH_AT_MOST_ONE = '?'.freeze

      # Creates a new Route that will associate a pattern to a
      # {Resource}.
      #
      # @example Standard route
      #   Route.new(["*"], MyResource)
      #
      # @example Guarded route
      #   Route.new ["/notes"],
      #     ->(request) { request.method == "POST" },
      #     Resources::Note
      #   Route.new ["/notes"], Resources::NoteList
      #   Route.new ["/notes", :id], Resources::Note
      #   Route.new ["/notes"], Resources::Note do |req|
      #     req.query['foo']
      #   end
      #
      # @overload initialize(path_spec, *guards, resource, bindings = {}, &block)
      #   @param [Array<String|Symbol>] path_spec a list of path
      #     segments (String) and identifiers (Symbol) to bind.
      #     Strings will be simply matched for equality. Symbols in
      #     the path spec will be extracted into {Request#path_info} for use
      #     inside your {Resource}. The special segment {MATCH_ALL} will match
      #     all remaining segments.
      #   @param [Proc] guards optional guard blocks called with the request.
      #   @param [Class] resource the {Resource} to dispatch to
      #   @param [Hash] bindings additional information to add to
      #     {Request#path_info} when this route matches
      #   @yield [req] an optional guard block
      #   @yieldparam [Request] req the request object
      # @see Dispatcher#add_route
      def initialize(path_spec, *args)
        if args.last.is_a? Hash
          bindings = args.pop
        else
          bindings = {}
        end

        resource = args.pop
        guards = args
        guards << Proc.new if block_given?

        @path_spec = path_spec
        @guards    = guards
        @resource  = resource
        @bindings  =  bindings

        raise ArgumentError, t('not_resource_class', :class => resource.name) unless resource < Resource
      end

      # Determines whether the given request matches this route and
      # should be dispatched to the {#resource}.
      # @param [Reqeust] request the request object
      def match?(request)
        tokens = request.uri.path.match(/^\/(.*)/)[1].split('/')
        bind(tokens, {}) && guards.all? { |guard| guard.call(request) }
      end

      # Decorates the request with information about the dispatch
      # route, including path bindings.
      # @param [Request] request the request object
      def apply(request)
        request.disp_path = request.uri.path.match(/^\/(.*)/)[1]
        request.path_info = @bindings.dup
        tokens = request.disp_path.split('/')
        depth, trailing = bind(tokens, request.path_info)
        request.path_tokens = trailing || []
      end

      private
      # Attempts to match the path spec against the path tokens, while
      # accumulating variable bindings.
      # @param [Array<String>] tokens the list of path segments
      # @param [Hash] bindings where path bindings will be stored
      # @return [Fixnum, Array<Fixnum, Array>, false] either the depth
      #   that the path matched at, the depth and tokens matched by
      #   {MATCH_ALL}, or false if it didn't match.
      def bind(tokens, bindings)
        depth = 0
        spec = @path_spec
        loop do
          case
          when spec.empty? && tokens.empty?
            return depth
          when spec == [MATCH_ALL]
            return [depth, tokens]
          when spec == [MATCH_AT_LEAST_ONE]
            return tokens.length >= 1 ? [depth, tokens] : false
          when spec == [MATCH_AT_MOST_ONE]
            return tokens.length <= 1 ? [depth, tokens] : false
          when tokens.empty?
            return false
          when Symbol === spec.first
            bindings[spec.first] = tokens.first
          when spec.first == tokens.first
          else
            return false
          end
          spec = spec[1..-1]
          tokens = tokens[1..-1]
          depth += 1
        end
      end

    end # class Route
  end # module Dispatcher
end # module Webmachine
