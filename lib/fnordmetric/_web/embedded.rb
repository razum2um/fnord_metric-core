class FnordMetric::Embedded

  def initialize(opts={})
    @opts = opts

    @opts[:server] ||= "thin"
    @opts[:host]   ||= "0.0.0.0"
    @opts[:port]   ||= "4242"

    middleware_stack = @opts[:use] || []

    websocket = FnordMetric::WebSocket.new

    webapp = if FnordMetric.options[:http_websocket_only]
      lambda { |env| [204, {}, [""]] }
    else
      FnordMetric::App.new(@opts)
    end

    builder = Rack::Builder.app do
      use Rack::CommonLogger
      use Rack::ShowExceptions

      map "/stream" do
        run websocket
      end

      map "/" do
        middleware_stack.each do |middleware| 
          use(*middleware[0..1], &middleware[2])
        end

        run webapp
      end
    end

    builder #.to_app
  end
end
