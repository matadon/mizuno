require 'rack/response'

module Mizuno
    class ClientResponse
        include Rack::Response::Helpers

        attr_accessor :url, :status, :headers, :body, :ssl, :timeout
        
        def initialize(url)
            @url = url
            @headers = Rack::Utils::HeaderHash.new
        end

        def [](key)
            @headers[key]
        end

        def []=(key, value)
            @headers[key] = value
        end

        def ssl?
            @ssl == true
        end

        def timeout?
            (@timeout == true) or (@status == 408)
        end

        def success?
            successful? or redirect?
        end
    end
end
