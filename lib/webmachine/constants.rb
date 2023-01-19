module Webmachine
  # Universal HTTP delimiter
  CRLF = "\r\n".freeze

  # HTTP Content-Type
  CONTENT_TYPE = 'Content-Type'.freeze

  # Default Content-Type
  TEXT_HTML = 'text/html'.freeze

  # HTTP Date
  DATE = 'Date'.freeze

  # HTTP Transfer-Encoding
  TRANSFER_ENCODING = 'Transfer-Encoding'.freeze

  # HTTP Content-Length
  CONTENT_LENGTH = 'Content-Length'.freeze

  # A underscore
  UNDERSCORE = '_'.freeze

  # A dash
  DASH = '-'.freeze

  # A Slash
  SLASH = '/'.freeze

  MATCHES_ALL = '*/*'.freeze

  GET_METHOD = 'GET'
  HEAD_METHOD = 'HEAD'
  POST_METHOD = 'POST'
  PUT_METHOD = 'PUT'
  DELETE_METHOD = 'DELETE'
  OPTIONS_METHOD = 'OPTIONS'
  TRACE_METHOD = 'TRACE'
  CONNECT_METHOD = 'CONNECT'

  STANDARD_HTTP_METHODS = [
    GET_METHOD, HEAD_METHOD, POST_METHOD,
    PUT_METHOD, DELETE_METHOD, TRACE_METHOD,
    CONNECT_METHOD, OPTIONS_METHOD
  ].map!(&:freeze)
  STANDARD_HTTP_METHODS.freeze

  # A colon
  COLON = ':'.freeze

  # http string
  HTTP = 'http'.freeze

  # Host string
  HOST = 'Host'.freeze

  # HTTP Content-Encoding
  CONTENT_ENCODING = 'Content-Encoding'.freeze

  # Charset string
  CHARSET = 'Charset'.freeze

  # Comma split match
  SPLIT_COMMA = /\s*,\s*/.freeze

  # Star Character
  STAR = '*'.freeze

  # HTTP Location
  LOCATION = 'Location'.freeze

  # identity Encoding
  IDENTITY = 'identity'.freeze

  SERVER = 'Server'.freeze
end
