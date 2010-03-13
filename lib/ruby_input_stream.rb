#!/usr/bin/env ruby

#
# Wraps a Java InputStream in a Ruby object, and provides IO-like read,
# gets, each, and rewind methods.
#
class RubyInputStream
    DEFAULT_BUFFER_SIZE = 1024

    def initialize(stream)
	# We wrap the Java 
	@stream = stream
    end

    #
    # Rewinds the stream to the beginning; throws an exception if this
    # stream doesn't support rewinding.
    #
    def rewind
	return unless(@stream.markSupported)
	@stream.reset
#        raise("This InputStream doesn't support mark/reset.") \
#	    unless(@stream.markSupported)
    end

    #
    # Iterates over each line in the stream.
    #
    def each
        while(line = gets)
	    yield(line)
	end
    end

    #
    # Reads a line from the stream; returns nil on EOF.
    #
    def gets
	buffer = ""
	bytes = Java::byte[DEFAULT_BUFFER_SIZE].new

	# Read in bytes and add them to the output buffer.
	while((count = @stream.readLine(bytes, 0, DEFAULT_BUFFER_SIZE)) != -1)
	    buffer << String.from_java_bytes(bytes)[0, count]

	    # Break if we hit a newline.
	    break if buffer[buffer.length - 1] == 10
	end

	# An empty buffer and EOF means we're done.
	return(nil) if ((count == -1) and buffer.empty?)

	# All done.
	return(buffer)
    end

    #
    # Reads data from the stream.  If [length] is not given, reads all
    # data; if not, reads [length] bytes.  If a string is passed as 
    # [buffer], the data is appended to that, rather than returning a 
    # new String.
    #
    def read(length = nil, buffer = nil)
        # If we get passed no length, read everything unitl EOF.
        read_everything = true unless length

        length ||= DEFAULT_BUFFER_SIZE
	buffer ||= ""
	bytes = Java::byte[length].new

	# Read in bytes and add them to the output buffer.
	while((count = @stream.read(bytes, 0, length)) != -1)
	    buffer << String.from_java_bytes(bytes)[0, count]
	    break unless read_everything
	end

	# Return nil if we've hit EOF and were called with a length.
	return(nil) if ((count == -1) and buffer.empty? \
	    and (not read_everything))

	# All done; if we're at EOF, then buffer will be empty.
	return(buffer)
    end
end
