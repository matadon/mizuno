#
# A test app that always returns a server error.
#
class RedirectApp
    def call(env)
        message = "REDIRECT"
        [ 301, { "Content-Type" => "text/plain",
            "Location" => "http://jkjdshfkadh.fds/",
            "Content-Length" => message.length.to_s }, [ message ] ]
    end
end
