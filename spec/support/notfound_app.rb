#
# A test app that always returns a server error.
#
class NotfoundApp
    def call(env)
        message = "NOT FOUND"
        [ 404, { "Content-Type" => "text/plain",
            "Content-Length" => message.length.to_s }, [ message ] ]
    end
end
