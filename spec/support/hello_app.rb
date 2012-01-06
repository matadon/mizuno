#
# The classic 'Hello, world!' Rack application.
#
class HelloApp
    def call(env)
        message = "Hello, world!"
        [ 200, { "Content-Type" => "text/plain", 
            "Content-Length" => message.length.to_s }, [ message  ] ]
    end
end
