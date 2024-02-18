module Webmachine
  # Helper methods for dealing with the 'quoted-string' type often
  # present in header values.
  module QuotedString
    # The pattern for a 'quoted-string' type
    QUOTED_STRING = /"((?:\\"|[^"])*)"/.freeze

    # The pattern for a 'quoted-string' type, without any other content.
    QS_ANCHORED = /^#{QUOTED_STRING}$/.freeze

    # Removes surrounding quotes from a quoted-string
    def unquote(str)
      if str =~ QS_ANCHORED
        unescape_quotes $1
      else
        str
      end
    end

    # Ensures that quotes exist around a quoted-string
    def quote(str)
      if QS_ANCHORED.match?(str)
        str
      else
        %("#{escape_quotes str}")
      end
    end

    # Escapes quotes within a quoted string.
    def escape_quotes(str)
      str.gsub('"', '\\"')
    end

    # Unescapes quotes within a quoted string
    def unescape_quotes(str)
      str.delete('\\')
    end
  end
end
