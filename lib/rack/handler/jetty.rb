#!/usr/bin/env ruby
#
# Runs a Rack application with Jetty as the webserver.
#

require 'java'
require 'rubygems'
require 'rack'
require 'rack_servlet'

# Make sure we're on JRuby.
raise("Rack::Handler::Jetty only runs on JRuby.") \
    unless (RUBY_PLATFORM =~ /java/)

# Load Jetty JARs.
path = 'lib/java/*.jar'
Dir[path].each { |jar| require jar }

# Include classes so we can use the short names.
classes = [ 'org.eclipse.jetty.servlet.DefaultServlet',
    'org.eclipse.jetty.server.Server',
    'org.eclipse.jetty.servlet.ServletContextHandler',
    'org.eclipse.jetty.servlet.ServletHolder',
    'org.eclipse.jetty.util.thread.QueuedThreadPool',
    'org.eclipse.jetty.server.nio.SelectChannelConnector',
    'org.eclipse.jetty.server.handler.ContextHandlerCollection',
    'org.cometd.server.continuation.ContinuationCometdServlet',
    'org.eclipse.jetty.continuation.ContinuationThrowable',
    'org.eclipse.jetty.servlet.FilterMapping' ]
classes.each { |c| include_class c }

class Rack::Handler::Jetty
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

	servlet = RackServlet.new
	servlet.addRackApplication(app)
	holder = ServletHolder.new(servlet)
	context.addServlet(holder, "/")

	# Add the context to the server and start.
	server.set_handler(context)
	server.start
    end
end

Rack::Handler.register 'jetty', 'Rack::Handler::Jetty'
