#!/usr/bin/env ruby

require 'java'
require 'lib/java/servlet-api-2.5.jar'
require 'ruby_input_stream'

include_class 'javax.servlet.http.HttpServlet'

#
# Wraps a Rack application in a Java servlet.
#
# FIXME: relativeResourceBase?
#
# http://rack.rubyforge.org/doc/SPEC.html
# http://java.sun.com/j2ee/sdk_1.3/techdocs/api/javax/servlet/http/HttpServlet.html
#
class RackServlet < HttpServlet
    include_class 'java.io.FileInputStream'

    #
    # [app] is a Rack application.
    #
    def addRackApplication(app)
        @app = app
    end

    def service(request, response)
	# Start populating the hash that we'll hand off.
        env = Hash.new
	env['REQUEST_METHOD'] = request.getMethod
	env['QUERY_STRING'] = request.getQueryString.to_s
	env['SERVER_NAME'] = request.getServerName
	env['SERVER_PORT'] = request.getServerPort.to_s
	env['rack.version'] = Rack::VERSION
	env['rack.url_scheme'] = request.getScheme

	# FIXME: Not sure what this should be...
	env['SCRIPT_NAME'] = ''

	# request.getPathInfo seems to be blank, so we're using the URI.
	env['PATH_INFO'] = request.getRequestURI

	# Rack says URI, but it hands off a URL.
	env['REQUEST_URI'] = request.getRequestURL.toString

	# Java chops off the query string, but a Rack application will
	# expect it, so we'll add it back if present
	env['REQUEST_URI'] << "?#{env['QUERY_STRING']}" \
	    if env['QUERY_STRING']

	env['rack.multiprocess'] = false
	env['rack.multithread'] = true
	env['rack.run_once'] = false
	env['HTTP_VERSION'] = request.getProtocol
	env['REMOTE_ADDR'] = request.getRemoteAddr
	env['REMOTE_HOST'] = request.getRemoteHost

	# FIXME: Should we set a default logger?
#	env['rack.session'] = nil

#	env['rack.logger']

	# Populate the HTTP headers.
	request.getHeaderNames.each do |header_name|
	    header = header_name.upcase.tr('-', '_')
	    env["HTTP_#{header}"] = request.getHeader(header_name)
	end

	# Rack fix: HTTP_CONTENT_TYPE should just be CONTENT_TYPE
	env["CONTENT_TYPE"] = env.delete("HTTP_CONTENT_TYPE") \
	    if env["HTTP_CONTENT_TYPE"]
	env["CONTENT_LENGTH"] = env.delete("HTTP_CONTENT_LENGTH") \
	    if env["HTTP_CONTENT_LENGTH"]

	# Set the input and output streams.
	env['rack.input'] = RubyInputStream.new(request.getInputStream)

	env['rack.errors'] = $stderr

	# Execute the Rack request.
	status, headers, body = @app.call(env)

	# Set the HTTP status code.
	response.setStatus(status)

	# Add all the result headers.
	# FIXME/TEST: Multiple Set-Cookie?
	headers.each_pair { |h, v| response.addHeader(h, v) }

	# Handle the result body.
	if(body.respond_to?(:to_path))

	    output = response.getOutputStream
	    buffer = Java::byte[1024].new
	    file = FileInputStream.new(body.to_path)
	    while((count = file.read(buffer)) != -1)
	        output.write(buffer, 0, count)
	    end
	    file.close
	else
	    output = response.getWriter
	    body.each { |l| output.print(l) }
	end

	# Close the body if we're supposed to.
	body.close if body.respond_to?(:close)

	# All done.
	output.flush
    end
end
