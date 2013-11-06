require 'java'

Mizuno.require_jars([ 'websocket/websocket-server',
                      'websocket/websocket-servlet',
                      'websocket/websocket-common',
                      'websocket/websocket-api' ])

module Mizuno
    module Websockets
        java_import 'org.eclipse.jetty.websocket.server.WebSocketHandler'

        #
        # Websockets Handler
        #
        class Handler < WebSocketHandler

            attr_accessor :creator

            def configure(factory)
                factory.setCreator(creator) if creator
            end

        end
    end
end
