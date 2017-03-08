require 'rack'

class Time
  def self.from_msgpack_ext(data)
    sec, usec = MessagePack.unpack(data)
    Time.at(sec, usec)
  end
  def to_msgpack_ext
    [to_i, usec].to_msgpack
  end
end

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
      msgpack_factory = MessagePack::Factory.new
      msgpack_factory.register_type(0x01, Time)
      @client = Client.new("http://0.0.0.0:#{@@server_port}/", factory: msgpack_factory)
      if @@is_stopped_test_app_server
        if /java/ =~ RUBY_PLATFORM
          mizuno = nil
          thread = Thread.new do
            Thread.current.abort_on_exception = true
            require 'mizuno/server'
            app = Rack::Builder.new {
              # MockHandler is in helper.rb
              run MessagePack::RPCOverHTTP::Server.app(MockHandler.new, msgpack_factory)
            }
            mizuno = Mizuno::Server.new
            mizuno.run(app, embedded: true, threads: 1, port: @@server_port, host: '0.0.0.0')
          end
          at_exit do
            mizuno.stop
            thread.kill
            thread.join
          end
        else
          pid = fork {
            Rack::Server.start(config: "test/mock_server.ru", Port: @@server_port, Host: '0.0.0.0')
            exit 0
          }
          at_exit do
            Process.kill(:INT, pid)
            Process.waitpid(pid)
          end
        end
        sleep_until_http_server_is_started("127.0.0.1", @@server_port)
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

    def test_call_with_ext_type
      require 'time'
      t1 = Time.parse('2017-03-08 13:59:00')
      t2 = Time.now
      assert_equal [t1, t2], @client.call(:test, t1, t2)
    end

    def test_call_async
      pend "msgpack-rpc-over-http does not support Client#async for jruby" if jruby?

      future = @client.call_async(:test, "a", "b")
      assert_equal ["a", "b"], future.value
      assert_raise(MessagePack::RPCOverHTTP::RuntimeError) do
        future = @client.call(:error)
        future.value
      end

      # multi-call
      (1..20).map{|i| [@client.call_async(:test, i), i] }.each do |f, i|
        assert_equal [i], f.value
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
      pend "msgpack-rpc-over-http does not support Client#stream for jruby" if jruby?
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
      pend "msgpack-rpc-over-http does not support Client#stream_async for jruby" if jruby?
      expect = ["a", "b"]
      future = @client.stream_async(:stream_normal, "a", "b") do |res|
        assert_equal expect.shift, res
      end
      future.value
    end
  end
end
