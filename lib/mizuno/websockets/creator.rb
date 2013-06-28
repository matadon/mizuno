module Mizuno
    module Websockets
        java_import 'org.eclipse.jetty.websocket.servlet.WebSocketCreator'

        #
        # Websockets creator
        #
        class Creator
            include WebSocketCreator

            attr_accessor :adapter

            java_signature %{@override Object createWebSocket(UpgradeRequest req, UpgradeResponse resp)}
            def createWebSocket(req, resp)
                @adapter
            end
        end
    end
end
