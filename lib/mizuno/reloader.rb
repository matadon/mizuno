require 'pathname'
require 'thread'

#:nodoc:
module Mizuno
    # 
    # Middleware for reloading production applications; works exactly
    # like Rack::Reloader, but rather than checking for any changed
    # file, only looks at one specific file.
    #
    # Also allows for explicit reloading via a class method.
    # 
    class Reloader
        class << self
            attr_accessor :logger, :trigger
        end

        def initialize(app, interval = 1)
            @app = app
            @interval = interval
            @trigger = self.class.trigger
            @logger = self.class.logger || $stderr
            @updated = @threshold = Time.now
            @files = {}
        end

        def call(env)
            Thread.exclusive { reload! } if (Time.now > @threshold)
            @app.call(env)
        end

        #
        # Reloads the application iff ou
        #
        def reload!(stderr = $stderr)
            @threshold += interval
            return unless (timestamp = mtime(@trigger))
            return unless (timestamp > @updated)

            paths = [ './', *$LOAD_PATH ].uniq
            files = [ $0, *$LOADED_FEATURES ].uniq.map do |file|
                next if file =~ /\.(so|bundle)$/
                @files[file] = mtime(find(file, paths))

                # Wrapped loader, doesn't actually load the file.
                load(file, true)

                yield(found, mtime)
            end

            # go over all loaded files
            # isolate full path to file if we don't have it
            # next unless mtime > @updated
            # test-load file, if pass, add to queue
            # if fail, add to error list and log
            # if no errors, reload

#            rotation do |file, mtime|
#                previous_mtime = @mtimes[file] ||= mtime
#                safe_load(file, mtime, stderr) if mtime > previous_mtime
#            end
            @updated = timestamp
        end

        #
        # A safe Kernel::load, issuing the hooks depending on the results
        #
        def safe_load(file, mtime, stderr = $stderr)
            load(file)
            stderr.puts "#{self.class}: reloaded `#{file}'"
            file
        rescue LoadError, SyntaxError => ex
            stderr.puts ex
        ensure
            @mtimes[file] = mtime
        end

        #
        # Takes a relative or absolute +file+ name, a couple possible
        # +paths+ that the +file+ might reside in. Returns the full path
        # and File::Stat for the path.
        #
        def find(file, paths)
            found = @files[file]

            found ||= file if Pathname.new(file).absolute?

            found, stat = safe_stat(found)
            return found, stat if found

            paths.find do |possible_path|
                path = ::File.join(possible_path, file)
                found, stat = safe_stat(path)
                return ::File.expand_path(found), stat if found
            end

            return false, false
        end

        #
        # Returns the modification time of _file_.
        #
        def mtime(file)
            begin
                return unless file
                stat = File.stat(file)
                stat.file? ? stat.mtime : nil
            rescue Errno::ENOENT, Errno::ENOTDIR
                nil
            end
        end
    end
end
