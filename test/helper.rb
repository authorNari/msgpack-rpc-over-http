require 'net/http'
require 'timeout'

class MockHandler
  include MessagePack::RPCOverHTTP::Server::Streamer

  class Error < MessagePack::RPCOverHTTP::RemoteError
  end

  def test(*args)
    return args
  end

  def stream_normal(*args)
    return stream { args.each{|arg| chunk(arg) } }
  end

  def stream_error(*args)
    return stream do
      args.each{|arg| chunk(arg) }
      raise "Error"
    end
  end

  def error
    raise "Something Error"
  end

  def user_defined_error
    raise Error, "Something Error"
  end
end

def jruby?
  if /java/ =~ RUBY_PLATFORM
    return true
  end
  false
end

def sleep_until_http_server_is_started(host, port)
  timeout(30) do
    while stopped_test_app_server?(host, port)
      sleep 1
    end
  end
end

def stopped_test_app_server?(host, port)
  begin
    Net::HTTP.get(host, '/', port)
    return false
  rescue => ex
    return true
  end
end
