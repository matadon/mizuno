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

    option :env do
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

    option :log do
        long '--log'
        desc 'logfile (defaults to stderr)'
        default nil
    end
        
    option :log4j do
      # e.g. jruby -J-Dlog4j.debug=true -J-Dlog4j.configuration=file:///log4j_config_dir/log4j.properties  /path_to_mizuno/mizuno --log4j
      long '--log4j'
      desc 'Disable default log4j configuration and allow confiuration via -J-Dlog4j.configuration=file://mypath/log4j.properties'
      default false
    end

    option :rewindable do
        long '--rewindable'
        desc 'rewindable input behavior per 1.x spec'
        default false
    end

    separator ''
    separator 'Mizuno-specific options: '

    option :daemonize do
        short '-D'
        long '--start'
        desc 'detach and run as a daemon'
        default false
    end

    option :stop do
        long '--stop'
        desc 'stop a running daemon'
        default false
    end

    option :kill do
        long '--stop'
        desc 'stop a running daemon'
        default false
    end

    option :status do
        long '--status'
        desc 'get the status of a running daemon'
        default false
    end

    option :reload do
        long '--reload'
        desc 'reloads a running mizuno instance'
        default false
    end

    option :restart do
        long '--restart'
        desc 'starts a new instance if needed when reloading'
        default false
    end

    option :reloadable do
        long '--reloadable'
        desc 'sets up live reloading via mizuno/reloader'
        default false
    end

    option :pidfile do
        short '-P'
        long '--pidfile'
        desc 'pidfile for when running as a daemon'
        default 'mizuno.pid'
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
            $stderr.puts Mizuno::Server.version
            exit            
        end
    end
end


