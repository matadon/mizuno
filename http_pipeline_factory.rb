java_import org.jboss.netty.channel.ChannelPipelineFactory

class HttpPipelineFactory
    include ChannelPipelineFactory

#    java_import 'org.jboss.netty.channel.Channels.*'
    java_import 'org.jboss.netty.channel.Channels'
    java_import org.jboss.netty.channel.ChannelPipeline
    java_import org.jboss.netty.handler.codec.http.HttpChunkAggregator
    java_import org.jboss.netty.handler.codec.http.HttpRequestDecoder
    java_import org.jboss.netty.handler.codec.http.HttpResponseEncoder
    java_import org.jboss.netty.handler.stream.ChunkedWriteHandler

    def getPipeline
        pipeline = Channels.pipeline
        pipeline.addLast("decoder", HttpRequestDecoder.new)
        pipeline.addLast("aggregator", HttpChunkAggregator.new(65536))
        pipeline.addLast("encoder", HttpResponseEncoder.new)
        pipeline.addLast("chunkedWriter", ChunkedWriteHandler.new)
        pipeline.addLast("handler", HttpFileServer.new)
        return(pipeline)
    end
end
