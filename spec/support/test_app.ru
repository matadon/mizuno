require 'rubygems'
require 'rack'
require 'test_app'

app = TestApp.new
rackup = Rack::Builder.app do
  use Rack::Chunked
  run app
end
run rackup
