require 'json/pure'

#
# A tiny Rack application for testing the Mizuno webserver.  Each of the
# following paths can be used to test webserver behavior:
#
# /ping:: Always returns 200 OK.
#
# /error/:number:: Returns the HTTP status code specified in the path.
#
# /echo:: Returns a plaintext rendering of the original request.
#
# /file:: Returns a file for downloading.
#
# /push:: Publishes a message to async listeners.
#
# /pull:: Recieves messages sent via /push using async.
#
# A request to any endpoint not listed above will return a 404 error.
#
class TestApp
    def initialize
        @subscribers = Array.new
    end

    def call(env)
        begin
            request = Rack::Request.new(env)
            method = request.path[/^\/(\w+)/, 1]
            return(error(request, 404)) if (method.nil? or method.empty?)
            return(error(request, 404)) unless respond_to?(method.to_sym)
            send(method.to_sym, request)
        rescue => error
            puts error
            puts error.backtrace
            error(nil, 500)
        end
    end

    def ping(request)
        [ 200, { "Content-Type" => "text/plain", 
            "Content-Length" => "2" }, [ "OK" ] ]
    end

    def error(request, code = nil)
        code ||= (request.path[/^\/\w+\/(\d+)/, 1] or "500")
        [ code.to_i, { "Content-Type" => "text/plain", 
            "Content-Length" => "5" }, [ "ERROR" ] ]
    end

    def echo(request)
        response = Rack::Response.new
        env = request.env.merge('request.params' => request.params)
        response.write(env.to_json)
        response.finish
    end

    def push(request)
        message = request.params['message']

        @subscribers.reject! do |subscriber|
            begin
                response = Rack::Response.new
                if(message.empty?)
                    subscriber.call(response.finish)
                    next(true)
                else
                    response.write(message)
                    subscriber.call(response.finish)
                    next(false)
                end
            rescue java.io.IOException => error
                next(true)
            end
        end

        ping(request)
    end

    def pull(request)
        @subscribers << request.env['async.callback']
        throw(:async)
    end

    def download(request)
        file = File.new('spec/data/reddit-icon.png', 'r')
        response = Rack::Response.new(file)
        response['Content-Type'] = 'image/png'
        response['Content-Disposition'] = \
            'attachment; filename=reddit-icon.png'
        response.finish
    end

    def upload(request)
        data = request.params['file'][:tempfile].read
        checksum = Digest::MD5.hexdigest(Base64.decode64(data))
        response = Rack::Response.new
        response.write(checksum)
        response.finish
    end
end
