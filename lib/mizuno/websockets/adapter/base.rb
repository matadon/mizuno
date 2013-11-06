module Mizuno
    module Websockets
        module Adapter

            java_import 'org.eclipse.jetty.websocket.api.WebSocketAdapter'

            #
            # Base WebSockets adapter
            #
            class Base < WebSocketAdapter

                def on_web_socket_text(message)                ; end
                def on_web_socket_error(cause)                 ; end
                def on_web_socket_binary(payload, offset, len) ; end
                def on_web_socket_close(status_code, reason)   ; end
                def on_web_socket_connect(sess)                ; end

                def onWebSocketError(cause)
                    on_web_socket_error(cause)
                end

                def onWebSocketText(message)
                    on_web_socket_text(message)
                end

                def onWebSocketBinary(payload, offset, len)
                    on_web_socket_binary(payload, offset, len)
                end

                def onWebSocketClose(status_code, reason)
                    super
                    on_web_socket_close(status_code, reason)
                end

                def onWebSocketConnect(sess)
                    super
                    on_web_socket_connect(sess)
                end

            end

        end
    end
end
