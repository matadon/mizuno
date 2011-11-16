require 'spec_helper'
require 'test_app'
require 'thread'
require 'digest/md5'
require 'base64'
require 'json/pure'

describe Mizuno do
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

    before(:all) do
        @lock = Mutex.new
        @app = Rack::Lint.new(TestApp.new)
        @options = { :host => '127.0.0.1', :port => 9201, 
            :embedded => true }
        Net::HTTP.version_1_2
        Mizuno::HttpServer.run(@app, @options)
    end

    after(:all) do
        Mizuno::HttpServer.stop
    end

    it "returns 200 OK" do
        response = get("/ping")
        response.code.should == "200"
    end

    it "returns 403 FORBIDDEN" do
        response = get("/error/403")
        response.code.should == "403"
    end

    it "returns 404 NOT FOUND" do
        response = get("/jimmy/hoffa")
        response.code.should == "404"
    end

    it "sets Rack headers" do
        response = get("/echo")
        response.code.should == "200"
        content = JSON.parse(response.body)
        content["rack.version"].should == [ 1, 1 ]
        content["rack.multithread"].should be_true
        content["rack.multiprocess"].should be_false
        content["rack.run_once"].should be_false
    end

    it "passes form variables via GET" do
        response = get("/echo?answer=42")
        response.code.should == "200"
        content = JSON.parse(response.body)
        content['request.params']['answer'].should == '42'
    end

    it "passes form variables via POST" do
        question = "What is the answer to life, the universe, and everything?"
        response = post("/echo", 'question' => question)
        response.code.should == "200"
        content = JSON.parse(response.body)
        content['request.params']['question'].should == question
    end

    it "passes custom headers" do
        response = get("/echo", "X-My-Header" => "Pancakes")
        response.code.should == "200"
        content = JSON.parse(response.body)
        content["HTTP_X_MY_HEADER"].should == "Pancakes"
    end

    it "lets the Rack app know it's running as a servlet" do
        response = get("/echo", 'answer' => '42')
        response.code.should == "200"
        content = JSON.parse(response.body)
        content['rack.java.servlet'].should be_true
    end

    it "is clearly Jetty" do
        response = get("/ping")
        response['server'].should =~ /jetty/i
    end

    it "sets the server port and hostname" do
        response = get("/echo")
        content = JSON.parse(response.body)
        content["SERVER_PORT"].should == "9201"
        content["SERVER_NAME"].should == "127.0.0.1"
    end

    it "passes the URI scheme" do
        response = get("/echo")
        content = JSON.parse(response.body)
        content['rack.url_scheme'].should == 'http'
    end

    it "supports file downloads" do
        response = get("/download")
        response.code.should == "200"
        response['Content-Type'].should == 'image/png'
        response['Content-Disposition'].should == \
            'attachment; filename=reddit-icon.png'
        checksum = Digest::MD5.hexdigest(response.body)
        checksum.should == '8da4b60a9bbe205d4d3699985470627e'
    end

    it "supports file uploads" do
        boundary = '349832898984244898448024464570528145'
        content = []
        content << "--#{boundary}"
        content << 'Content-Disposition: form-data; name="file"; ' \
            + 'filename="reddit-icon.png"'
        content << 'Content-Type: image/png'
        content << 'Content-Transfer-Encoding: base64'
        content << ''
        content << Base64.encode64( \
            File.read('spec/data/reddit-icon.png')).strip
        content << "--#{boundary}--"
        body = content.map { |l| l + "\r\n" }.join('')
        headers = { "Content-Type" => \
            "multipart/form-data; boundary=#{boundary}" }
        response = post("/upload", nil, headers, body)
        response.code.should == "200"
        response.body.should == '8da4b60a9bbe205d4d3699985470627e'
    end

    it "handles async requests" do
        lock = Mutex.new
        buffer = Array.new

        clients = 10.times.map do |index|
            Thread.new do 
                Net::HTTP.start(@options[:host], @options[:port]) do |http|
                    response = http.get("/pull")
                    lock.synchronize { 
                        buffer << "#{index}: #{response.body}" }
                end
            end
        end

        lock.synchronize { buffer.should be_empty }
        post("/push", 'message' => "one")
        clients.each { |c| c.join }
        lock.synchronize { buffer.should_not be_empty }
        lock.synchronize { buffer.count.should == 10 }
    end

    pending "logs to a custom logger" do
    end
end
