module Webmachine
  module HeaderNegotiation
    extend self
    def ensure_date_header(res)
      if (200..499).include?(res.code)
        res.headers['Date'] ||= Time.now.httpdate
      end
    end

    def ensure_content_length(res)
      body = res.body
      case
      when res.headers['Transfer-Encoding']
        return
      when [204, 205, 304].include?(res.code)
        res.headers.delete 'Content-Length'
      when body != nil
        res.headers['Content-Length'] = body.respond_to?(:bytesize) ? body.bytesize.to_s : body.length.to_s
      else
        res.headers['Content-Length'] = '0'
      end
    end
  end
end
