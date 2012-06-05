require 'erb'
module Webmachine
  module Trace
    # Implements the user-interface of the visual debugger. This
    # includes serving the static files (the PNG flow diagram, CSS and
    # JS for the UI) and the HTML for the individual traces.
    class TraceResource < Resource

      MAP_EXTERNAL = %w{static map.png}
      MAP_FILE = File.expand_path("../static/http-headers-status-v3.png", __FILE__)
      SCRIPT_EXTERNAL = %w{static wmtrace.js}
      SCRIPT_FILE = File.expand_path("../#{SCRIPT_EXTERNAL.join '/'}", __FILE__)
      STYLE_EXTERNAL = %w{static wmtrace.css}
      STYLE_FILE = File.expand_path("../#{STYLE_EXTERNAL.join '/'}", __FILE__)
      TRACELIST_ERB = File.expand_path("../static/tracelist.erb", __FILE__)
      TRACE_ERB = File.expand_path("../static/trace.erb", __FILE__)

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
          [["text/html", :produce_list]]
        when MAP_EXTERNAL
          [["image/png", :produce_file]]
        when SCRIPT_EXTERNAL
          [["text/javascript", :produce_file]]
        when STYLE_EXTERNAL
          [["text/css", :produce_file]]
        else
          [["text/html", :produce_trace]]
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
        File.read(@file)
      end

      def produce_list
        traces = Trace.traces
        self.class.tracelist.result(binding)
      end

      def produce_trace
        data = Trace.fetch(@trace)
        treq, tres, trace = encode_trace(data)
        name = @trace
        self.class.trace.result(binding)
      end
    end
  end
end
