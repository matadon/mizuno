# Load our local copy of Mizuno before anything else.
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

# All dependencies for testing.
require 'yaml'
require 'net/http'
require 'thread'
require 'digest/md5'
require 'base64'
require 'json/pure'
require 'rack/urlmap'
require 'rack/lint'
require 'mizuno/server'

Thread.abort_on_exception = true

RSpec.configure do |config|
end

module HttpRequests
    def get(path, headers = {})
        Net::HTTP.start(@options[:host], @options[:port]) do |http|
            request = Net::HTTP::Get.new(path, headers)
            http.request(request)
        end
    end

    def post(path, params = nil, headers = {}, body = nil)
        Net::HTTP.start(@options[:host], @options[:port]) do |http|
            request = Net::HTTP::Post.new(path, headers)
            request.form_data = params if params
            request.body = body if body
            http.request(request)
        end
    end

    def start_server(app, options)
        @lock = Mutex.new
        @app = app
        @rackup = Rack::Builder.app do
            use Rack::Chunked
            use Rack::Lint
            run app
        end
        @options = options
        Net::HTTP.version_1_2
        Mizuno::Server.run(@rackup, @options)
    end

    def stop_server
        Mizuno::Server.stop
    end
end

