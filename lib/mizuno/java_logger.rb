require 'logger'

module Mizuno
    class JavaLogger < Logger
        java_import 'java.io.ByteArrayInputStream'
        java_import 'java.util.Properties'
        java_import 'org.apache.log4j.PropertyConfigurator'

        LEVELS = {
            Logger::DEBUG => Java.org.apache.log4j.Level::DEBUG,
            Logger::INFO => Java.org.apache.log4j.Level::INFO,
            Logger::WARN => Java.org.apache.log4j.Level::WARN,
            Logger::ERROR => Java.org.apache.log4j.Level::ERROR,
            Logger::FATAL => Java.org.apache.log4j.Level::FATAL }

        #
        # Configure Log4J.
        #
        # FIXME: What if this gets called twice?
        #
        def JavaLogger.configure(options = {})
            return if @options
            @options = options

            # Default logging threshold.
            limit = options[:warn] ? "WARN" : "ERROR"
            limit = "DEBUG" if ($DEBUG or options[:debug])

            # FIXME: logger.error is being marked INFO
            limit = 'INFO'

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

            # Create the default logger that gets used everywhere.
            @logger = new
        end

        def JavaLogger.logger
            @logger
        end

        def initialize
            @log4j = Java.org.apache.log4j.Logger.getLogger('ruby')
        end

        def add(severity, message = nil, progname = nil)
            content = (message or (block_given? and yield) or progname)
            @log4j.log(LEVELS[severity], content)
        end

        def puts(message)
            write(message.to_s)
        end

        def write(message)
            add(INFO, message)
        end

        def flush
            # No-op.
        end

        def close
            # No-op.
        end
    end
end
