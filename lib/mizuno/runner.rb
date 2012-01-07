#
# FIXME: Add SSL.
#
module Mizuno
    class Runner
        def Runner.start!
            # Default rackup is in config.ru
            config = (Choice.rest.first or "config.ru")

            # Create an options hash with only symbols.
            choices = Choice.choices.merge(:config => config)
            options = Hash[choices.map { |k, v| [ k.to_sym, v ] }]

            # Resolve relative paths to the logfile, etc.
            root = options[:root]
            options[:pidfile] = Runner.resolve_path(root, options[:pidfile])
            options[:log] = Runner.resolve_path(root, options[:log])
            options[:public] = Runner.resolve_path(root, options[:public])

            # Require multiple libraries.
            options.delete(:require).each { |r| require r }

            # Use our own custom daemonization code.
            Runner.daemonize(:daemonize => options.delete(:daemonize),
                :pidfile => options.delete(:pidfile),
                :user => options.delete(:user),
                :group => options.delete(:group))

            # Fire up Mizuno as if it was called from Rackup.
            server = Rack::Server.new
            server.options = options.merge(:server => 'mizuno')
            server.start
        end

        def Runner.daemonize(options)
            # FIXME: Implement.
        end

        def Runner.resolve_path(root, path)
            return(path) unless path.is_a?(String)
            return(path) if (path =~ /^\//)
            File.expand_path(File.join(root, path))
        end
    end
end

Choice.options do
    separator ''
    separator 'Ruby options: '

    option :eval do
        short '-e'
        long '--eval'
        desc 'evaluate a line of code'
        default nil
    end

    option :debug do
        short '-d'
        long '--debug'
        desc 'set debugging flags (set $DEBUG to true)'
        default false
    end

    option :warn do
        short '-w'
        long '--warn'
        desc 'turn warnings on for your script'
        default false
    end

    option :include do
        short '-I'
        long '--include *PATHS'
        desc 'specify $LOAD_PATH (may be used more than once)'
        default []
    end

    option :require do
        short '-r'
        long '--require *GEMS'
        desc 'require a gem (may be used more than once)'
        default []
    end

    separator ''
    separator 'Rack options: '

    option :host do
        short '-o'
        long '--host'
        desc 'the address to listen on'
        default '0.0.0.0'
    end

    option :port do
        short '-p'
        long '--port'
        desc 'the port to listen on'
        cast Integer
        default 9292
    end

    option :environment do
        short '-E'
        long '--env'
        desc 'application environment'
        default 'development'
    end

    option :threads do
        long '--threads'
        desc 'maximum size of the thread pool'
        cast Integer
        default 50
    end

    option :daemonize do
        short '-D'
        long '--daemonize'
        desc 'detach and run as a daemon'
        default false
    end

    option :pidfile do
        short '-P'
        long '--pidfile'
        desc 'pidfile for when running as a daemon'
        default 'mizuno.pid'
    end

    option :log do
        long '--log'
        desc 'logfile (defaults to stderr)'
        default $stderr
    end

    option :user do
        long '--user'
        desc 'user to run as'
        default nil
    end

    option :group do
        long '--group'
        desc 'group to run as'
        default nil
    end

    option :root do
        long '--root'
        desc 'app root (defaults to the current directory)'
        default Dir.pwd
    end

    option :public do
        long '--public'
        desc 'public file path (defaults to ./public)'
        default 'public'
    end

    separator ''
    separator 'Common options: '

    option :help do
        short '-h'
        long '--help'
        desc 'Show this message'
        action { Choice.help }
    end

    option :version do
        short '-v'
        long '--version'
        desc 'Show version'
        action do
            puts Mizuno::HttpServer.version
            exit            
        end
    end
end

