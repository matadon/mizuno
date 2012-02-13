# Load our local copy of Mizuno before anything else.
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

# All dependencies for testing.
require 'mizuno'
require 'yaml'
require 'net/http'
require 'thread'
require 'digest/md5'
require 'base64'
require 'json/pure'
require 'rack/urlmap'
require 'rack/lint'
require 'support/test_app'

Thread.abort_on_exception = true

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
end

