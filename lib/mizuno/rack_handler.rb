require 'stringio'
require 'rack/response'

#
# Wraps a Rack application in a Jetty handler.
#
module Mizuno
    java_import 'org.eclipse.jetty.server.handler.AbstractHandler'

    class RackHandler < AbstractHandler
        java_import 'java.io.FileInputStream'
        java_import 'org.eclipse.jetty.continuation.ContinuationSupport'

        # Regex for splitting on newlines.
        NEWLINE = /\n/

        def initialize(server)
            @server = server
            super()
        end

        #
        # Sets the Rack application that handles requests sent to this
        # Jetty handler.
        #
        def rackup(app)
            @app = app
        end

        java_signature %{@Override void handle(String target,
            Request baseRequest, HttpServletRequest request,
            HttpServletResponse response) throws IOException, ServletException}

        #
        # Takes an incoming request (as a HttpServletRequest) and dispatches
        # it to the rack application setup via [rackup]. All this really
        # involves is translating the various bits of the Servlet API into
        # the Rack API on the way in, and translating the response back on
        # the way out.
        #
        # Also, we implement a common extension to the Rack api for
        # asynchronous request processing.  We supply an 'async.callback' 
        # parameter in env to the Rack application.  If we catch an
        # :async symbol thrown by the app, we initiate a Jetty continuation.
        #
        # When 'async.callback' gets a response with empty headers and an
        # empty body, we declare the async response finished.
        #
        def handle(target, base_request, request, response)
            handle_exceptions(response) do
                # Turn the ServletRequest into a Rack env hash
                env = servlet_to_rack(request)

                # Handle asynchronous responses via Servlet continuations.
                continuation = ContinuationSupport.getContinuation(request)

                # If this is an expired connection, do nothing.
                return if continuation.isExpired

                # We should never be re-dispatched.
                raise("Request re-dispatched.") unless continuation.isInitial

                # Add our own special bits to the rack environment so that 
                # Rack middleware can have access to the Java internals.
                env['rack.java.servlet'] = true
                env['rack.java.servlet.request'] = request
                env['rack.java.servlet.response'] = response
                env['rack.java.servlet.continuation'] = continuation

                # Add an callback that can be used to add results to the
                # response asynchronously.
                env['async.callback'] = Proc.new do |rack_response|
                    servlet_response = continuation.getServletResponse
                    rack_to_servlet(rack_response, servlet_response) \
                        and continuation.complete
                end

                # Execute the Rack request.
                catch(:async) do
                    rack_response = @app.call(env)
                   
                    # For apps that don't throw :async.
                    unless(rack_response[0] == -1)
                        # Nope, nothing asynchronous here.
                        rack_to_servlet(rack_response, response)
                        return
                    end
                end

                # If we got here, this is a continuation.
                continuation.suspend(response)
            end
        end

        private

        #
        # Turns a Servlet request into a Rack request hash.
        #
        def servlet_to_rack(request)
            # The Rack request that we will pass on.
            env = Hash.new

            # Map Servlet bits to Rack bits.
            env['REQUEST_METHOD'] = request.getMethod
            env['QUERY_STRING'] = request.getQueryString.to_s
            env['SERVER_NAME'] = request.getServerName
            env['SERVER_PORT'] = request.getServerPort.to_s
            env['rack.version'] = Rack::VERSION
            env['rack.url_scheme'] = request.getScheme
            env['HTTP_VERSION'] = request.getProtocol
            env["SERVER_PROTOCOL"] = request.getProtocol
            env['REMOTE_ADDR'] = request.getRemoteAddr
            env['REMOTE_HOST'] = request.getRemoteHost

            # request.getPathInfo seems to be blank, so we're using the URI.
            env['REQUEST_PATH'] = request.getRequestURI
            env['PATH_INFO'] = request.getRequestURI
            env['SCRIPT_NAME'] = ""

            # Rack says URI, but it hands off a URL.
            env['REQUEST_URI'] = request.getRequestURL.to_s

            # Java chops off the query string, but a Rack application will
            # expect it, so we'll add it back if present
            env['REQUEST_URI'] << "?#{env['QUERY_STRING']}" \
                if env['QUERY_STRING']

            # JRuby is like the matrix, only there's no spoon or fork().
            env['rack.multiprocess'] = false
            env['rack.multithread'] = true
            env['rack.run_once'] = false

            # The input stream is a wrapper around the Java InputStream.
            env['rack.input'] = @server.rewindable(request)

            # Force encoding if we're on Ruby 1.9
            env['rack.input'].set_encoding(Encoding.find("ASCII-8BIT")) \
                if env['rack.input'].respond_to?(:set_encoding)

            # Populate the HTTP headers.
            request.getHeaderNames.each do |header_name|
                header = header_name.to_s.upcase.tr('-', '_')
                env["HTTP_#{header}"] = request.getHeader(header_name)
            end

            # Rack Weirdness: HTTP_CONTENT_TYPE and HTTP_CONTENT_LENGTH
            # both need to have the HTTP_ part dropped.
            env["CONTENT_TYPE"] = env.delete("HTTP_CONTENT_TYPE") \
                if env["HTTP_CONTENT_TYPE"]
            env["CONTENT_LENGTH"] = env.delete("HTTP_CONTENT_LENGTH") \
                if env["HTTP_CONTENT_LENGTH"]

            # Route errors through the logger.
            env['rack.errors'] ||= @server.logger
            env['rack.logger'] ||= @server.logger

            # All done, hand back the Rack request.
            return(env)
        end

        #
        # Turns a Rack response into a Servlet response; can be called
        # multiple times.  Returns true if this is the full request (either
        # a synchronous request or the last part of an async request),
        # false otherwise.
        #
        # Note that keep-alive *only* happens if we get either a pathname
        # (because we can find the length ourselves), or if we get a 
        # Content-Length header as part of the response.  While we can
        # readily buffer the response object to figure out how long it is,
        # we have no guarantee that we aren't going to be buffering
        # something *huge*.
        #
        # http://docstore.mik.ua/orelly/java-ent/servlet/ch05_03.htm
        #
        def rack_to_servlet(rack_response, response)
            # Split apart the Rack response.
            status, headers, body = rack_response

            # We assume the request is finished if we got empty headers,
            # an empty body, and we have a committed response.
            finished = (headers.empty? and \
                body.respond_to?(:empty?) and body.empty?)
            return(true) if (finished and response.isCommitted)

            # No need to send headers again if we've already shipped 
            # data out on an async request.
            unless(response.isCommitted)
                # Set the HTTP status code.
                response.setStatus(status.to_i)

                # Servlets require that we set Content-Length and
                # Content-Type differently than other headers.
                content_length = headers.delete('Content-Length') \
                    and response.setContentLength(content_length.to_i)
                content_type = headers.delete('Content-Type') \
                    and response.setContentType(content_type)

                # Add all the result headers.
                headers.each { |h, v| v.split(NEWLINE).each { |l|
                    response.addHeader(h, l) } }
            end

            # How else would we write output?
            output = response.getOutputStream

            # Turn the body into something nice and Java-y.
            if(body.respond_to?(:to_path))
                # We've been told to serve a file; use FileInputStream to
                # stream the file directly to the servlet, because this
                # is a lot faster than doing it with Ruby.
                file = java.io.File.new(body.to_path)

                # We set the content-length so we can use Keep-Alive,
                # unless this is an async request.
                response.setContentLength(file.length) \
                    unless content_length

                # Stream the file directly.
                buffer = Java::byte[4096].new
                input_stream = FileInputStream.new(file)
                while((count = input_stream.read(buffer)) != -1)
                    output.write(buffer, 0, count)
                end
                input_stream.close
            else
                body.each do |chunk|
                    output.write(chunk.to_java_bytes)
                    output.flush
                end
            end

            # Close the body if we're supposed to.
            body.close if body.respond_to?(:close)

            # All done.
            output.flush
        end

        #
        # Handle exceptions, returning a generic 500 error response.
        #
        def handle_exceptions(response)
            begin
                yield
            rescue => error
                message = "Exception: #{error}"
                message << "\n#{error.backtrace.join("\n")}" \
                    if (error.respond_to?(:backtrace))
                Server.logger.error(message)
                return if response.isCommitted
                response.reset
                response.setStatus(500)
            end
        end
    end
end
