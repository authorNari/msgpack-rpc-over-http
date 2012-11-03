module MessagePack::RPCOverHTTP
  class TestClient < Test::Unit::TestCase
    def self.unused_port
      s = TCPServer.open(0)
      port = s.addr[1]
      s.close
      port
    end

    @@server_port = unused_port
    @@is_stopped_test_app_server = true

    def setup
      @client = Client.new("http://0.0.0.0:#{@@server_port}/")
      if @@is_stopped_test_app_server
        pid = fork {
          Rack::Server.start(config: "test/mock_server.ru", Port: @@server_port)
          exit 0
        }
        at_exit do
          Process.kill(:INT, pid)
          Process.waitpid(pid)
        end
        sleep_until_http_server_is_started("0.0.0.0", @@server_port)
        @@is_stopped_test_app_server = false
      end
    end

    def test_call
      assert_equal ["a", "b"], @client.call(:test, "a", "b")
      assert_raise(MessagePack::RPCOverHTTP::RuntimeError) do
        @client.call(:error)
      end
      assert_raise(MockHandler::Error) do
        @client.call(:user_defined_error)
      end
    end

    def test_call_async
      future = @client.call_async(:test, "a", "b")
      assert_equal ["a", "b"], future.value
      assert_raise(MessagePack::RPCOverHTTP::RuntimeError) do
        future = @client.call(:error)
        future.value
      end
    end

    def test_callback
      future = @client.callback(:test, "a", "b") do |res|
        assert_equal ["a", "b"], res
      end
      future.value
      future = @client.callback(:error) do |res, err|
        assert_kind_of MessagePack::RPCOverHTTP::RuntimeError, err
      end
      future.value
    end

    def test_stream
      expect = ["a", "b"]
      @client.stream(:stream_normal, "a", "b") do |res|
        assert_equal expect.shift, res
      end

      expect = ["a", "b"]
      @client.stream(:stream_error) do |res, err|
        if res
          assert_equal expect.shift, res
        else
          assert_kind_of MessagePack::RPCOverHTTP::RuntimeError, err
        end
      end
    end

    def test_stream_async
      expect = ["a", "b"]
      future = @client.stream_async(:stream_normal, "a", "b") do |res|
        assert_equal expect.shift, res
      end
      future.value
    end
  end
end
