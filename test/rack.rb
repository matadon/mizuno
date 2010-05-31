#require 'test/spec'

begin
require 'rack/handler/mizuno'
require 'rack/urlmap'
require 'rack/lint'
require 'testrequest'

Thread.abort_on_exception = true

context "Rack::Handler::Mizuno" do
    include TestApp::Helpers

    before(:all) do
	@app = Rack::Lint.new(TestApp.new)
	@options = { :Host => '0.0.0.0', :Port => 9201 }
        @server = Rack::Handler::Mizuno::HttpServer.run(@app, @options)
    end

    specify "should respond" do
        lambda { GET("/test") }.should_not raise_error
    end

    specify "should be using Jetty" do
        GET("/test")
        status.should == 200
	response['rack.java.servlet'].should_not be_nil
        response["HTTP_VERSION"].should == "HTTP/1.1"
        response["SERVER_PROTOCOL"].should == "HTTP/1.1"
        response["SERVER_PORT"].should == "9201"
        response["SERVER_NAME"].should == "0.0.0.0"
    end

    specify "should have rack headers" do
        GET("/test")
        response["rack.version"].should == [1,1]
        response["rack.multithread"].should be_true
        response["rack.multiprocess"].should be_false
        response["rack.run_once"].should be_false
    end

    specify "should have CGI headers on GET" do
        GET("/test")
        response["REQUEST_METHOD"].should == "GET"
        response["REQUEST_PATH"].should == "/test"
        response["PATH_INFO"].should == "/test"
        response["QUERY_STRING"].should == ""
        response["test.postdata"].should == ""

        GET("/test/foo?quux=1")
        response["REQUEST_METHOD"].should == "GET"
        response["REQUEST_PATH"].should == "/test/foo"
        response["PATH_INFO"].should == "/test/foo"
        response["QUERY_STRING"].should == "quux=1"
    end

    specify "should have CGI headers on POST" do
        POST("/test", {"rack-form-data" => "23"}, {'X-test-header' => '42'})
        status.should == 200
        response["REQUEST_METHOD"].should == "POST"
        response["REQUEST_PATH"].should == "/test"
        response["QUERY_STRING"].should == ""
        response["HTTP_X_TEST_HEADER"].should == "42"
        response["test.postdata"].should == "rack-form-data=23"
    end

    specify "should support HTTP auth" do
        GET("/test", {:user => "ruth", :passwd => "secret"})
        response["HTTP_AUTHORIZATION"].should == "Basic cnV0aDpzZWNyZXQ="
    end

    specify "should set status" do
        GET("/test?secret")
        status.should == 403
        response["rack.url_scheme"].should == "http"
    end

#    teardown do
#    end
end

rescue LoadError => e
    $stderr.puts e
    $stderr.puts e.backtrace
    $stderr.puts "Skipping Rack::Handler::Mizuno tests (Mizuno is required). `gem install mizuno` and try again."
end
