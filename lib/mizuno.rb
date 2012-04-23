#
# A Rack handler for Jetty 8.
#
# Written by Don Werve <don@madwombat.com>
#

require 'java'

# Save our launch environment for spawning children later.
module Mizuno
    LAUNCH_ENV = $LOAD_PATH.map { |i| "-I#{i}" }.push($0)

    HOME = File.expand_path(File.dirname(__FILE__))

    #
    # Tell log4j not to complain to the console about a missing
    # log4j.properties file, as we configure it programmatically in
    # Mizuno::Server (http://stackoverflow.com/questions/6849887)
    #
    def Mizuno.initialize_logger
        require_jars(%w(log4j slf4j-api slf4j-log4j12))
        Java.org.apache.log4j.Logger.getRootLogger.setLevel( \
            Java.org.apache.log4j.Level::INFO)
    end

    #
    # Loads jarfiles independent of versions.
    #
    def Mizuno.require_jars(*names)
        names.flatten.each do |name|
            file = Dir[File.join(HOME, 'java', "#{name}-*.jar")].first
            file ||= Dir[File.join(HOME, 'java', "#{name}.jar")].first
            raise("Unknown or missing jar: #{name}") unless file
            require file
        end
    end
end

Mizuno.initialize_logger
