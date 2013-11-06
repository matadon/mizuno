require 'mizuno/websockets/adapter/base'

module Mizuno
    module Websockets
        module Adapter

            #
            # Example echo adapter. Sends back received message
            #
            class Echo < Base

                def on_web_socket_text(message)
                    session.remote.send_string_by_future(message);
                end

            end

        end
    end
end
