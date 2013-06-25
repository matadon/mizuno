require 'mizuno/client_response'

module Mizuno
    java_import 'org.eclipse.jetty.client.util.FutureResponseListener'
    java_import 'org.eclipse.jetty.client.HttpContentResponse'

    class ClientResponseListener < FutureResponseListener
        def initialize(request, &block)
            super(request)

            @callback = block
        end

        def onComplete(result)
            super

            req    = result.getRequest()
            resp = result.getResponse()

            response                = ClientResponse.new(req.getURI())
            response.ssl        = (req.getScheme() == 'https')
            response.status = resp.getStatus()
            response.body     = getContent()

            @callback.call(response)
        end
    end
end
