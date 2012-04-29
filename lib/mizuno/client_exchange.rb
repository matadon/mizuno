require 'stringio'
require 'mizuno/client_response'

module Mizuno
    java_import 'org.eclipse.jetty.client.ContentExchange'

    # what do I want to happen on a timeout or error?

    class ClientExchange < ContentExchange
        def initialize(client)
            super(false)
            @client = client
        end

        def setup(url, options = {}, &block)
            @callback = block
            @response = ClientResponse.new(url)
            setURL(url)
            @response.ssl = (getScheme == 'https')
            setMethod((options[:method] or "GET").upcase)
            headers = options[:headers] and headers.each_pair { |k, v| 
                setRequestHeader(k, v) }
            return unless options[:body]
            body = StringIO.new(options[:body].read)
            setRequestContentSource(body.to_inputstream) 
        end

        def onResponseHeader(name, value)
            @response[name.to_s] = value.to_s
        end

        def onResponseComplete
            @client.clear(self)
            @response.status = getResponseStatus
            @response.body = getResponseContent
            run_callback
        end

        def onExpire
            @client.clear(self)
            @response.timeout = true
            @response.status = -1
            @response.body = nil
            run_callback
        end

        def onException(error)
            @exception ||= error
        end

        def onConnectionFailed(error)
            @exception ||= error
        end

        def run_callback
            begin
                @callback.call(@response)
            rescue => error
                onException(error)
            end
        end

        def waitForDone
            super
            throw(@exception) if @exception
        end
#
#        def finished?
#            #FIXME: Implement.
#        end
    end
end
