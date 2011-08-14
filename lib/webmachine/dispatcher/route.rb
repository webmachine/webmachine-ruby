require 'webmachine/resource'
require 'webmachine/translation'

module Webmachine
  module Dispatcher
    # Pairs URIs with {Resource} classes in the {Dispatcher}. To
    # create routes, use {Dispatcher#add_route}.
    class Route
      # @return [Class] the resource this route will dispatch to, a
      #   subclass of {Resource}
      attr_reader :resource

      # When used in a path specification, will match all remaining
      # segments
      MATCH_ALL = '*'.freeze

      # Creates a new Route that will associate a pattern to a
      # {Resource}.
      # @param [Array<String|Symbol>] path_spec a list of path
      #   segments (String) and identifiers (Sybmol) to bind.
      #   Strings will be simply matched for equality. Symbols in
      #   the path spec will be extracted into {Request#path_info} for use
      #   inside your {Resource}. The special segment {MATCH_ALL} will match
      #   all remaining segments.
      # @param [Class] resource the {Resource} to dispatch to
      # @param [Hash] bindings additional information to add to
      #   {Request#path_info} when this route matches
      # @see {Dispatcher#add_route}
      def initialize(path_spec, resource, bindings={})
        @path_spec, @resource, @bindings = path_spec, resource, bindings
        raise ArgumentError, t('not_resource_class', :class => resource.name) unless resource < Resource
      end

      # Determines whether the given request matches this route and
      # should be dispatched to the {#resource}.
      def match?(request)
        tokens = request.uri.path.match(/^\/(.*)/)[1].split('/')
        bind(tokens, {})
      end

      # Decorates the request with information about the dispatch
      # route, including path bindings.
      # @param [Request] the request object
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
    end
  end
end
