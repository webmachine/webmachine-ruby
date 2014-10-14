require 'webmachine/constants'

module Webmachine
  module HeaderNegotiation
    include Constants
    def ensure_date_header(res)
      if (200..499).include?(res.code)
        res.headers[DATE] ||= Time.now.httpdate
      end
    end

    def ensure_content_length(res)
      body = res.body
      case
      when res.headers[TRANSFER_ENCODING]
        return
      when [204, 205, 304].include?(res.code)
        res.headers.delete CONTENT_LENGTH
      when body != nil
        res.headers[CONTENT_LENGTH] = body.respond_to?(:bytesize) ? body.bytesize.to_s : body.length.to_s
      else
        res.headers[CONTENT_LENGTH] = '0'
      end
    end
  end
end
