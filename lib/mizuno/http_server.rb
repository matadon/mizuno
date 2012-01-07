module Mizuno
    class HttpServer
        include_class 'java.util.Properties'
        include_class 'org.apache.log4j.PropertyConfigurator'
        include_class 'org.eclipse.jetty.server.Server'
        include_class 'org.eclipse.jetty.servlet.ServletContextHandler'
        include_class 'org.eclipse.jetty.servlet.ServletHolder'
        include_class 'org.eclipse.jetty.server.nio.SelectChannelConnector'
        include_class 'org.eclipse.jetty.util.thread.QueuedThreadPool'
        include_class 'org.eclipse.jetty.servlet.DefaultServlet'

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
        # FIXME: Add SSL suport.
        #
        def HttpServer.run(app, options = {})
            # Symbolize and downcase keys.
            options = Hash[options.map { |k, v| 
                [ k.to_s.downcase.to_sym, v ] }]

            # The Jetty server
            configure_logging(options)
            @server = Server.new

            # Thread pool
            thread_pool = QueuedThreadPool.new
            thread_pool.min_threads = [ options[:threads] / 10, 1 ].max
            thread_pool.max_threads = [ options[:threads], 3 ].max
            @server.set_thread_pool(thread_pool)

            # Connector
            connector = SelectChannelConnector.new
            connector.setPort(options[:port].to_i)
            connector.setHost(options[:host])
            @server.addConnector(connector)

            # Servlet context.
            context = ServletContextHandler.new(nil, "/", 
                ServletContextHandler::NO_SESSIONS)

            # The servlet itself.
            rack_servlet = RackServlet.new
            rack_servlet.rackup(app)
            holder = ServletHolder.new(rack_servlet)
            context.addServlet(holder, "/")

            # options[:public]
            # options[:statistics]

            # Add the context to the server and start.
            @server.set_handler(context)
            @server.start
            puts "#{version} on #{connector.host}:#{connector.port}"

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
            puts "Stopping Jetty..."
            @server.stop
        end

        #
        # Returns the full version string.
        #
        def HttpServer.version
            "Mizuno 0.4.2 (Jetty #{Server.getVersion})"
        end

#        include_class 'org.slf4j.LoggerFactory'

#        include_class "org.eclipse.jetty.util.log.Slf4jLog"
        include_class 'org.apache.log4j.ConsoleAppender'
        include_class 'org.apache.log4j.FileAppender'
        include_class 'org.apache.log4j.PatternLayout'
        include_class 'java.io.ByteArrayInputStream'

        #
        # Set up logging through Log4J and Logback, which is about a
        # million times more complicated than Logger.
        #
        def HttpServer.configure_logging(options)
            # --log will do a combined log
            # --request-log will split off the request log

            properties = Properties.new
            properties.load(ByteArrayInputStream.new(<<-END.to_java_bytes))
                # Default to logging everything to the console.
                log4j.rootCategory = INFO, CONSOLE

                # Jetty logs go to the console as well.
                log4j.logger.org.eclipse.jetty.util.log = CONSOLE

                # CONSOLE is set to be a ConsoleAppender using a PatternLayout.
                log4j.appender.CONSOLE = org.apache.log4j.ConsoleAppender
                log4j.appender.CONSOLE.Threshold = INFO
                log4j.appender.CONSOLE.layout = org.apache.log4j.PatternLayout
                log4j.appender.CONSOLE.layout.ConversionPattern = %d %p %m

                # FILE is set to be a File appender using a PatternLayout.
                log4j.appender.FILE = org.apache.log4j.FileAppender
                log4j.appender.FILE.File = mizuno.log
                log4j.appender.FILE.Append = true
                log4j.appender.FILE.Threshold = INFO
                log4j.appender.FILE.layout = org.apache.log4j.PatternLayout
                log4j.appender.FILE.layout.ConversionPattern = %d %p %m
            END
            PropertyConfigurator.configure(properties)

#            root = Java.org.apache.log4j.Logger.getRootLogger
#            console = ConsoleAppender.new(PatternLayout.new( \
#                PatternLayout::TTCC_CONVERSION_PATTERN))
#            root.addAppender(console)

            # Have Jetty log to stdout for the time being.
            #java.lang.System.setProperty("org.eclipse.jetty.util.log.class", 
            #    "org.eclipse.jetty.util.log.StdErrLog")

            # http://synapticloop.com/blog/2011/01/setting-up-or-turning-off-jetty-7-logging-programmatically/
            # Direct output to a logfile if specified.

            # Where do we put our logs?
#            logfile = File.expand_path(log = @config['logfile'])
            logfile = 'mizuno.log'


#            org.eclipse.jetty.util.log.class

            # Configure Log4J.
            # log4j.logger.org.eclipse.jetty=INFO
#            properties = Properties.new
#            properties.setProperty('org.eclipse.jetty.LEVEL', 'WARN')
#            properties.setProperty('log4j.logger.org.eclipse.jetty',
#                'WARNING')
#            properties.setProperty('log4j.rootLogger', 'debug, file')
#            properties.setProperty('log4j.appender.file',
#                'org.apache.log4j.FileAppender')
#            properties.setProperty('log4j.appender.file.layout',
#               'org.apache.log4j.SimpleLayout')
#            properties.setProperty('log4j.appender.file.file',
#                logfile)
#            properties.setProperty('log4j.appender.file.append',
#                'true')
#            PropertyConfigurator.configure(properties)

#            java.lang.System.setProperty("org.eclipse.jetty.util.log.class", 
#                "org.eclipse.jetty.util.log.Slf4jLog")

Java.java.lang.System.setProperty( \
    'log4j.logger.org.apache.log4j.PropertyConfigurator', 'INFO')
Java.java.lang.System.setProperty( \
    'log4j.logger.org.apache.log4j.config.PropertySetter', 'INFO')
Java.java.lang.System.setProperty( \
    'log4j.logger.org.apache.log4j.FileAppender', 'INFO')

#            logger = Slf4jLog.new
#            Java.org.eclipse.jetty.util.log.Log.setLog(logger)
        end

    end
end

# Register ourselves with Rack when this file gets loaded.
Rack::Handler.register 'mizuno', 'Mizuno::HttpServer'

# Ensure that we shutdown the server on exit.
at_exit { Mizuno::HttpServer.stop }
