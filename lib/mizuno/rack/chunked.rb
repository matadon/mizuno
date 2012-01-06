require 'rack/utils'

#
# We replace the default Rack::Chunked implementation with a non-op
# version, as Jetty handles chunking for us.
#
module Rack
    class Chunked
        include Rack::Utils

        def initialize(app)
            @app = app
        end

        def call(env)
            @app.call(env)
        end
    end
end
