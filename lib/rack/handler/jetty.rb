#
# A Rack::Handler for Jetty 7.
#

require 'java'
#require 'rubygems'
require 'rack'
require 'rack/servlet'

# Make sure we're on JRuby.
raise("Rack::Handler::Jetty only runs on JRuby.") \
    unless (RUBY_PLATFORM =~ /java/)

# Load Jetty JARs.
jars = %w(cometd-api-1.0.0rc0.jar
    cometd-java-server-1.0.0rc0.jar
    jetty-continuation-7.0.1.v20091125.jar
    jetty-http-7.0.1.v20091125.jar
    jetty-io-7.0.1.v20091125.jar
    jetty-jmx-7.0.1.v20091125.jar
    jetty-security-7.0.1.v20091125.jar
    jetty-server-7.0.1.v20091125.jar
    jetty-servlet-7.0.1.v20091125.jar
    jetty-servlets-7.0.1.v20091125.jar
    jetty-util-7.0.1.v20091125.jar
    servlet-api-2.5.jar)

jars.each { |jar|
    require File.join(File.dirname(__FILE__), '..', '..', 'java', jar) }
#Dir[path].each { |jar| require jar }

class Rack::Handler::Jetty
    # Include various Jetty classes so we can use the short names.
#    include_class 'org.eclipse.jetty.servlet.DefaultServlet'
    include_class 'org.eclipse.jetty.server.Server'
    include_class 'org.eclipse.jetty.servlet.ServletContextHandler'
    include_class 'org.eclipse.jetty.servlet.ServletHolder'
    include_class 'org.eclipse.jetty.util.thread.QueuedThreadPool'
    include_class 'org.eclipse.jetty.server.nio.SelectChannelConnector'
#    include_class 'org.eclipse.jetty.server.handler.ContextHandlerCollection'
#    include_class 'org.cometd.server.continuation.ContinuationCometdServlet'
#    include_class 'org.eclipse.jetty.continuation.ContinuationThrowable'
#    include_class 'org.eclipse.jetty.servlet.FilterMapping'

    def self.run(app, options = {})
	# The Jetty server
	server = Server.new

	# Thread pool
	thread_pool = QueuedThreadPool.new
	thread_pool.min_threads = 5
	thread_pool.max_threads = 200
	server.set_thread_pool(thread_pool)

	# Connector
	connector = SelectChannelConnector.new
	connector.port = options[:Port].to_i
	server.addConnector(connector)

	# Servlet context.
	context = ServletContextHandler.new(nil, "/", 
	    ServletContextHandler::NO_SESSIONS)

	# The servlet itself.
	servlet = RackServlet.new
	servlet.rackup(app)
	holder = ServletHolder.new(servlet)
	context.addServlet(holder, "/")

	# Add the context to the server and start.
	server.set_handler(context)
	server.start
    end
end

# Register ourselves with Rack when this file gets loaded.
Rack::Handler.register 'jetty', 'Rack::Handler::Jetty'
