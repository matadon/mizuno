include_class org.jboss.netty.channel.SimpleChannelUpstreamHandler

class HttpFileServer < SimpleChannelUpstreamHandler
#    include_class org.jboss.netty.handler.codec.http.HttpHeaders.*
    include_class org.jboss.netty.handler.codec.http.HttpHeaders
#    include_class org.jboss.netty.handler.codec.http.HttpHeaders.Names.*
#    include_class org.jboss.netty.handler.codec.http.HttpMethod.*
#    include_class org.jboss.netty.handler.codec.http.HttpResponseStatus.*
#    include_class org.jboss.netty.handler.codec.http.HttpVersion.*
    include_class org.jboss.netty.handler.codec.http.HttpVersion
#    include_class java.io.File
#    include_class java.io.FileNotFoundException
#    include_class java.io.RandomAccessFile
#    include_class java.io.UnsupportedEncodingException
#    include_class java.net.URLDecoder
    include_class org.jboss.netty.buffer.ChannelBuffers
    include_class java.nio.ByteBuffer
#    include_class org.jboss.netty.channel.Channel
#    include_class org.jboss.netty.channel.ChannelFuture
    include_class org.jboss.netty.channel.ChannelFutureListener
#    include_class org.jboss.netty.channel.ChannelFutureProgressListener
#    include_class org.jboss.netty.channel.ChannelHandlerContext
#    include_class org.jboss.netty.channel.DefaultFileRegion
#    include_class org.jboss.netty.channel.ExceptionEvent
#    include_class org.jboss.netty.channel.FileRegion
#    include_class org.jboss.netty.channel.MessageEvent
    include_class org.jboss.netty.handler.codec.frame.TooLongFrameException
    include_class org.jboss.netty.handler.codec.http.DefaultHttpResponse
#    include_class org.jboss.netty.handler.codec.http.HttpRequest
#    include_class org.jboss.netty.handler.codec.http.HttpResponse
    include_class org.jboss.netty.handler.codec.http.HttpResponseStatus
#    include_class org.jboss.netty.handler.ssl.SslHandler
#    include_class org.jboss.netty.handler.stream.ChunkedFile
    include_class org.jboss.netty.util.CharsetUtil

    def messageReceived(context, event)
        request = event.getMessage
        response = DefaultHttpResponse.new(HttpVersion::HTTP_1_1, 
	    HttpResponseStatus::OK)
	output = "Hello, world!".to_java_bytes
#	response.setContent(output)
	buffer = ChannelBuffers.wrappedBuffer(output)
#	buffer = ByteBuffer.wrap(output.to_java_bytes)
        HttpHeaders.setContentLength(response, output.length)
        channel = event.getChannel
	future = channel.write(buffer)
	future.addListener(ChannelFutureListener.CLOSE);

    end
end
