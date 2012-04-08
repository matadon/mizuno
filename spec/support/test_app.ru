require 'rubygems'
require 'rack'
require 'test_app'
require 'mizuno/reloader'

app = TestApp.new
rackup = Rack::Builder.app do
    use Rack::Chunked
    use Mizuno::Reloader
    run app
end
run rackup
