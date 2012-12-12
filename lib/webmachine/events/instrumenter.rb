require 'securerandom'

module Webmachine
  module Events
    class Instrumenter
      def initialize(publisher)
        @publisher = publisher
      end

      def instrument(name, payload = {})
        transaction_id = unique_id

        @publisher.start(name, transaction_id, payload)

        begin
          yield
        rescue Exception => e
          payload[:exception] = [e.class.name, e.message, e.backtrace]
          raise
        ensure
          @publisher.finish(name, transaction_id, payload)
        end
      end

      private

      def unique_id
        SecureRandom.hex(10)
      end
    end
  end
end
