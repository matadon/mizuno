require 'rack/utils'

#
# We replace the default Rack::Chunked implementation with a non-op
# version, as Jetty handles chunking for us.
#
module Rack
  class Chunked
    include Rack::Utils

    class Body
      include Rack::Utils

      def initialize(body)
        @body = body
      end

      def each(&block)
        @body.each(&block)
      end

      def close
        @body.close if @body.respond_to?(:close)
      end
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    end
  end
end
