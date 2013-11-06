class WebsocketApp
  def call(env)
    begin
      request = Rack::Request.new(env)
      method = request.path[/^\/(\w+)/, 1]
      return(error(request, 404)) if (method.nil? or method.empty?)
      return(error(request, 404)) unless respond_to?(method.to_sym)
      send(method.to_sym, request)
    rescue => error
      puts error
      puts error.backtrace
      error(nil, 500)
    end
  end

  def index(request)
    page = <<-HTML
    <html><body>
      <script>
      function connect_socket () {
        var ws = new WebSocket("ws://localhost:9292/");
        ws.onopen = function()
        {
          // Web Socket is connected, send data using send()
          ws.send("Message to send");
          console.log("Message is sent...");
        };
        ws.onmessage = function (evt)
        {
          var received_msg = evt.data;
          console.log("Message is received...");
        };
        ws.onclose = function()
        {
          // websocket is closed.
          console.log("Connection is closed...");
        };
      }
      </script>
      <a href="#" onclick="connect_socket()">Connect!</a>
    </body></html>
    HTML

    [ 200, { "Content-Type" => "text/html",
            "Content-Length" => page.size.to_s }, [ page ] ]
  end

  def error(request, code = nil)
    code ||= (request.path[/^\/\w+\/(\d+)/, 1] or "500")
    [ code.to_i, { "Content-Type" => "text/plain",
        "Content-Length" => "5" }, [ "ERROR" ] ]
  end
end
