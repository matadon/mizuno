require 'pathname'
require 'thread'

#:nodoc:
module Mizuno
    # 
    # Middleware for reloading production applications; works exactly
    # like Rack::Reloader, but rather than checking for any changed
    # file, only looks at one specific file.
    #
    # Also allows for explicit reloading via a class method, as well as
    # by sending a SIGHUP to the process.
    # 
    class Reloader
        @reloaders = []

        @trigger = 'tmp/restart.txt'

        class << self
            attr_accessor :logger, :trigger, :reloaders
        end

        def Reloader.reload!
            reloaders.each { |r| r.reload!(true) }
        end

        def Reloader.add(reloader)
            Thread.exclusive do
                @logger ||= Mizuno::Server.logger
                @reloaders << reloader
            end
        end

        def initialize(app, interval = 1)
            Reloader.add(self)
            @app = app
            @interval = interval
            @trigger = self.class.trigger
            @logger = self.class.logger
            @updated = @threshold = Time.now.to_i
        end

        #
        # Reload @app on request.
        #
        def call(env)
            Thread.exclusive { reload! }
            @app.call(env)
        end

        #
        # Reloads the application if (a) we haven't reloaded in
        # @interval seconds, (b) the trigger file has been touched
        # since our last check, and (c) some other thread hasn't handled
        # the update.
        #
        def reload!(force = false)
            return unless (Time.now.to_i > @threshold)
            @threshold = Time.now.to_i + @interval
            return unless (force or \
                ((timestamp = mtime(@trigger)).to_i > @updated))
            timestamp ||= Time.now.to_i

            # Check updated files to ensure they're loadable.
            missing, errors = 0, 0
            files = find_files_for_reload do |file, file_mtime|
                next(missing += 1 and nil) unless file_mtime
                next unless (file_mtime >= @updated)
                next(errors += 1 and nil) unless verify(file)
                file
            end

            # Cowardly fail if we can't load something.
            @logger.debug("#{missing} files missing during reload.") \
                if (missing > 0)
            return(@logger.error("#{errors} errors, not reloading.")) \
                if (errors > 0)

            # Reload everything that's changed.
            files.each do |file|
                next unless file
                @logger.info("Reloading #{file}")
                load(file) 
            end
            @updated = timestamp
        end

        #
        # Walk through the list of every file we've loaded.
        #
        def find_files_for_reload
            paths = [ './', *$LOAD_PATH ].uniq
            [ $0, *$LOADED_FEATURES ].uniq.map do |file|
                next if file =~ /\.(so|bundle)$/
                yield(find(file, paths))
            end
        end

        #
        # Returns true if the file is loadable; uses the wrapper
        # functionality of Kernel#load to protect the global namespace.
        #
        def verify(file)
            begin
                @logger.debug("Verifying #{file}")
                load(file, true)
                return(true)
            rescue => error
                @logger.error("Failed to verify #{file}: #{error.to_s}")
                error.backtrace.each { |l| @logger.error("    #{l}") }
            end
        end

        #
        # Takes a relative or absolute +file+ name, a couple possible
        # +paths+ that the +file+ might reside in. Returns a tuple of
        # the full path where the file was found and its modification
        # time, or nil if not found.
        #
        def find(file, paths)
            if(Pathname.new(file).absolute?)
                return unless (timestamp = mtime(file))
                @logger.debug("Found #{file}")
                [ file, timestamp ]
            else
                paths.each do |path|
                    fullpath = File.expand_path((File.join(path, file)))
                    next unless (timestamp = mtime(fullpath))
                    @logger.debug("Found #{file} in #{fullpath}")
                    return([ fullpath, timestamp ])
                end
                return(nil)
            end
        end

        #
        # Returns the modification time of _file_.
        #
        def mtime(file)
            begin
                return unless file
                stat = File.stat(file)
                stat.file? ? stat.mtime.to_i : nil
            rescue Errno::ENOENT, Errno::ENOTDIR, Errno::ESRCH
                nil
            end
        end
    end
end

# Reload on SIGHUP.
trap("SIGHUP") { Mizuno::Reloader.reload! }
