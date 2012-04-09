require 'mizuno/version'
require 'mizuno/java_logger'
require 'mizuno/reloader'

module Mizuno
    class HttpServer
        include_class 'java.util.Properties'
        include_class 'java.io.ByteArrayInputStream'
        include_class 'org.apache.log4j.PropertyConfigurator'
        include_class 'org.eclipse.jetty.server.Server'
        include_class 'org.eclipse.jetty.servlet.ServletContextHandler'
        include_class 'org.eclipse.jetty.servlet.ServletHolder'
        include_class 'org.eclipse.jetty.server.nio.SelectChannelConnector'
        include_class 'org.eclipse.jetty.util.thread.QueuedThreadPool'
#        include_class 'org.eclipse.jetty.servlet.DefaultServlet'
#        include_class 'org.eclipse.jetty.server.handler.HandlerCollection'
#        include_class 'org.eclipse.jetty.server.handler.RequestLogHandler'
#        include_class 'org.eclipse.jetty.server.NCSARequestLog'

        #
        # Provide accessors so we can set a custom logger and a location
        # for static assets.
        #
        class << self
            attr_accessor :logger
        end

        #
        # Start up an instance of Jetty, running a Rack application.
        # Options can be any of the follwing, and are not
        # case-sensitive:
        #
        # :host::
        #     String specifying the IP address to bind to; defaults 
        #     to 0.0.0.0.
        #
        # :port::
        #     String or integer with the port to bind to; defaults 
        #     to 9292.
        #
        # http://wiki.eclipse.org/Jetty/Tutorial/RequestLog
        #
        # FIXME: Add SSL suport.
        #
        def HttpServer.run(app, options = {})
            # Symbolize and downcase keys.
            @options = options = Hash[options.map { |k, v| 
                [ k.to_s.downcase.to_sym, v ] }]
            options[:quiet] ||= true if options[:embedded]

            # The Jetty server
            configure_logging(options)
            @server = Server.new
            @server.setSendServerVersion(false)

            # Thread pool
            threads = options[:threads] || 50
            thread_pool = QueuedThreadPool.new
            thread_pool.min_threads = [ threads.to_i / 10, 5 ].max
            thread_pool.max_threads = [ threads.to_i, 10 ].max
            @server.set_thread_pool(thread_pool)

            # Connector
            connector = SelectChannelConnector.new
            connector.setPort(options[:port].to_i)
            connector.setHost(options[:host])
            @server.addConnector(connector)

            # Switch to a different user or group if we were asked to.
            Runner.setgid(options) if options[:group]
            Runner.setuid(options) if options[:user]

            # Servlet handler.
            app_handler = ServletContextHandler.new(nil, "/", 
                ServletContextHandler::NO_SESSIONS)

            # Optionally wrap with Mizuno::Reloader.
            threshold = (ENV['RACK_ENV'] == 'production' ? 10 : 1)
            app = Mizuno::Reloader.new(app, threshold) \
                if options[:reloadable]

            # The servlet itself.
            rack_servlet = RackServlet.new
            rack_servlet.rackup(app)
            holder = ServletHolder.new(rack_servlet)
            app_handler.addServlet(holder, "/")

#            # Our request log.
#            request_log = NCSARequestLog.new
#            request_log.setLogTimeZone("GMT")
#            request_log_handler = RequestLogHandler.new
#            request_log_handler.setRequestLog(request_log)
#
#            # Add handlers in order.
#            handlers = HandlerCollection.new
#            handlers.addHandler(request_log_handler)
#            handlers.addHandler(app_handler)

            # Add the context to the server and start.
            @server.set_handler(app_handler)
            @server.start
            $stderr.printf("%s listening on %s:%s\n", version,
                connector.host, connector.port) unless options[:quiet]

            # If we're embeded, we're done.
            return if options[:embedded]

            # Stop the server when we get The Signal.
            trap("SIGINT") { @server.stop and exit }

            # Join with the server thread, so that currently open file
            # descriptors don't get closed by accident.
            # http://www.ruby-forum.com/topic/209252
            @server.join
        end

        #
        # Shuts down an embedded Jetty instance.
        #
        def HttpServer.stop
            return unless @server
            $stderr.print "Stopping Jetty..." unless @options[:quiet]
            @server.stop
            $stderr.puts "done." unless @options[:quiet]
        end

        #
        # Returns the full version string.
        #
        def HttpServer.version
            "Mizuno #{Mizuno::VERSION} (Jetty #{Server.getVersion})"
        end

        #
        # Configure Log4J.
        #
        def HttpServer.configure_logging(options)
            return if @logger

            # Default logging threshold.
            limit = options[:warn] ? "WARN" : "ERROR"
            limit = "DEBUG" if ($DEBUG or options[:debug])

            # Base logging configuration.
            config = <<-END
                log4j.rootCategory = #{limit}, default
                log4j.logger.org.eclipse.jetty.util.log = #{limit}, default
                log4j.logger.ruby = INFO, ruby
                log4j.appender.default.Threshold = #{limit}
                log4j.appender.default.layout = org.apache.log4j.PatternLayout
                log4j.appender.default.layout.ConversionPattern = %d %p %m
                log4j.appender.ruby.Threshold = INFO
                log4j.appender.ruby.layout = org.apache.log4j.PatternLayout
                log4j.appender.ruby.layout.ConversionPattern = %m
            END

            # Should we log to the console?
            config.concat(<<-END) unless options[:log]
                log4j.appender.default = org.apache.log4j.ConsoleAppender
                log4j.appender.ruby = org.apache.log4j.ConsoleAppender
            END

            # Are we logging to a file?
            config.concat(<<-END) if options[:log]
                log4j.appender.default = org.apache.log4j.FileAppender
                log4j.appender.default.File = #{options[:log]}
                log4j.appender.default.Append = true
                log4j.appender.ruby = org.apache.log4j.FileAppender
                log4j.appender.ruby.File = #{options[:log]}
                log4j.appender.ruby.Append = true
            END

            # Set up Log4J via Properties.
            properties = Properties.new
            properties.load(ByteArrayInputStream.new(config.to_java_bytes))
            PropertyConfigurator.configure(properties)

            # Use log4j for our logging as well.
            @logger = JavaLogger.new
        end
    end
end

# Ensure that we shutdown the server on exit.
at_exit { Mizuno::HttpServer.stop }
