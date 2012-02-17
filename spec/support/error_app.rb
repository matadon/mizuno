#
# A test app that always returns a server error.
#
class ErrorApp
    def call(env)
        message = "ERROR"
        [ 500, { "Content-Type" => "text/plain", 
            "Content-Length" => message.length.to_s }, [ message ] ]
    end
end
