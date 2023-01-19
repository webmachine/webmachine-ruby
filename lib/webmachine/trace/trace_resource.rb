require 'erb'
require 'multi_json'

module Webmachine
  module Trace
    # Implements the user-interface of the visual debugger. This
    # includes serving the static files (the PNG flow diagram, CSS and
    # JS for the UI) and the HTML for the individual traces.
    class TraceResource < Resource
      MAP_EXTERNAL = %w[static map.png]
      MAP_FILE = File.expand_path('../static/http-headers-status-v3.png', __FILE__)
      SCRIPT_EXTERNAL = %w[static wmtrace.js]
      SCRIPT_FILE = File.expand_path("../#{SCRIPT_EXTERNAL.join "/"}", __FILE__)
      STYLE_EXTERNAL = %w[static wmtrace.css]
      STYLE_FILE = File.expand_path("../#{STYLE_EXTERNAL.join "/"}", __FILE__)
      TRACELIST_ERB = File.expand_path('../static/tracelist.erb', __FILE__)
      TRACE_ERB = File.expand_path('../static/trace.erb', __FILE__)

      # The ERB template for the trace list
      def self.tracelist
        @@tracelist ||= ERB.new(File.read(TRACELIST_ERB))
      end

      # The ERB template for a single trace
      def self.trace
        @@trace ||= ERB.new(File.read(TRACE_ERB))
      end

      def content_types_provided
        case request.path_tokens
        when []
          [['text/html', :produce_list]]
        when MAP_EXTERNAL
          [['image/png', :produce_file]]
        when SCRIPT_EXTERNAL
          [['text/javascript', :produce_file]]
        when STYLE_EXTERNAL
          [['text/css', :produce_file]]
        else
          [['text/html', :produce_trace]]
        end
      end

      def resource_exists?
        case request.path_tokens
        when []
          true
        when MAP_EXTERNAL
          @file = MAP_FILE
          File.exist?(MAP_FILE)
        when SCRIPT_EXTERNAL
          @file = SCRIPT_FILE
          File.exist?(SCRIPT_FILE)
        when STYLE_EXTERNAL
          @file = STYLE_FILE
          File.exist?(STYLE_FILE)
        else
          @trace = request.path_tokens.first
          Trace.traces.include? @trace
        end
      end

      def last_modified
        File.mtime(@file) if @file
      end

      def expires
        (Time.now + 30 * 86400).utc if @file
      end

      def produce_file
        # TODO: Add support for IO objects as response bodies,
        # allowing server optimizations like sendfile or chunked
        # downloads
        File.binread(@file)
      end

      def produce_list
        base = request.uri.path.chomp('/')
        traces = Trace.traces.map { |t| [t, "#{base}/#{t}"] }
        self.class.tracelist.result(binding)
      end

      def produce_trace
        data = Trace.fetch(@trace)
        treq, tres, trace = encode_trace(data)
        name = @trace
        self.class.trace.result(binding)
      end

      def encode_trace(data)
        data = data.dup
        # Request is first, response is last
        treq = data.shift.dup
        tres = data.pop.dup
        treq.delete :type
        tres.delete :type
        [MultiJson.dump(treq), MultiJson.dump(tres), MultiJson.dump(encode_decisions(data))]
      end

      def encode_decisions(decisions)
        decisions.each_with_object([]) do |event, list|
          case event[:type]
          when :decision
            # Don't produce new decisions for sub-steps in the graph
            unless /[a-z]$/.match?(event[:decision].to_s)
              list << {'d' => event[:decision], 'calls' => []}
            end
          when :attempt
            list.last['calls'] << {
              'call' => event[:name],
              'source' => event[:source],
              'input' => event[:args] && event[:args].inspect
            }
          when :result
            list.last['calls'].last['output'] = event[:value].inspect
          when :exception
            list.last['calls'].last['exception'] = {
              'class' => event[:class],
              'backtrace' => event[:backtrace].join("\n"),
              'message' => event[:message]
            }
          end
        end
      end
    end
  end
end
