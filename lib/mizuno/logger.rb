require 'logger'

module Mizuno
    class Logger < ::Logger
        java_import 'java.io.ByteArrayInputStream'
        java_import 'java.util.Properties'
        java_import 'org.apache.log4j.PropertyConfigurator'

        LEVELS = {
            ::Logger::DEBUG => Java.org.apache.log4j.Level::DEBUG,
            ::Logger::INFO => Java.org.apache.log4j.Level::INFO,
            ::Logger::WARN => Java.org.apache.log4j.Level::WARN,
            ::Logger::ERROR => Java.org.apache.log4j.Level::ERROR,
            ::Logger::FATAL => Java.org.apache.log4j.Level::FATAL }

        #
        # Configure Log4J.
        #
        def Logger.configure(options = {})
            return if @options
            @options = options

            # Default logging threshold.
            limit = options[:warn] ? "WARN" : "ERROR"
            limit = "DEBUG" if ($DEBUG or options[:debug])

            if !options[:log4j]
              # Base logging configuration.
              config = <<-END
                  log4j.rootCategory = #{limit}, default
                  log4j.logger.org.eclipse.jetty.util.log = #{limit}, default
                  log4j.appender.default.Threshold = #{limit}
                  log4j.appender.default.layout = org.apache.log4j.PatternLayout
              END

              # Should we log to the console?
              config.concat(<<-END) unless options[:log]
                  log4j.appender.default = org.apache.log4j.ConsoleAppender
                  log4j.appender.default.layout.ConversionPattern = %m\\n
              END

              # Are we logging to a file?
              config.concat(<<-END) if options[:log]
                  log4j.appender.default = org.apache.log4j.FileAppender
                  log4j.appender.default.Append = true
                  log4j.appender.default.File = #{options[:log]}
                  log4j.appender.default.layout.ConversionPattern = %d %p %m\\n
              END

              # Set up Log4J via Properties.
              properties = Properties.new
              properties.load(ByteArrayInputStream.new(config.to_java_bytes))
              PropertyConfigurator.configure(properties)
            end

            # Create the default logger that gets used everywhere.
            @logger = new
        end

        def Logger.logger
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
