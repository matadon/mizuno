require 'thread'
require 'mizuno'
Mizuno.require_jars(%w(jetty-client jetty-http jetty-io jetty-util))
require 'mizuno/client_response'
require 'mizuno/client_response_listener'

module Mizuno
    class Client
        java_import 'org.eclipse.jetty.client.HttpClient'
        java_import 'org.eclipse.jetty.util.thread.QueuedThreadPool'

        @lock = Mutex.new

        def Client.request(*args, &block)
            @lock.synchronize { @root ||= new }
            @root.request(*args, &block)
        end

        def Client.stop
            @lock.synchronize do
                return unless @root
                @root.stop
                @root = nil
            end
        end

        def initialize(options = {})
            defaults = { :timeout => 60 }
            options = defaults.merge(options)
            @client = HttpClient.new
            # TODO: @client.setConnectorType(HttpClient::CONNECTOR_SELECT_CHANNEL)
            @client.setMaxConnectionsPerDestination(100)
            # TODO: @client.setThreadPool(QueuedThreadPool.new(50))
            @client.setConnectTimeout(options[:timeout] * 1000)
            @client.start
            @lock = Mutex.new
            @listeners = []
        end

        def stop(wait = true)
            wait and @lock.synchronize do
                @listeners.each { |e| e.get(5, java.util.concurrent.TimeUnit::SECONDS) }
                @listeners.clear
            end
            @client.stop
        end

        def clear(listener)
            return unless @lock.try_lock
            @listeners.delete(listener)
            @lock.unlock
        end

        def request(url, options = {}, &block)

            request = @client.newRequest(url)

            listener = Mizuno::ClientResponseListener.new(request, &block)
            @lock.synchronize { @listeners << listener }

            request.send(listener)

            return(listener)
        end
    end
end

