#\ -s thin

### NOTE: this file is not used with jruby. FIX test/test_client.rb #setup if this file is fixed.

$LOAD_PATH.unshift(File.expand_path("./../lib", File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'msgpack-rpc-over-http'
require 'helper'

class Time
  def self.from_msgpack_ext(data)
    sec, usec = MessagePack.unpack(data)
    Time.at(sec, usec)
  end
  def to_msgpack_ext
    [to_i, usec].to_msgpack
  end
end
msgpack_factory = MessagePack::Factory.new
msgpack_factory.register_type(0x01, Time)

run MessagePack::RPCOverHTTP::Server.app(MockHandler.new, msgpack_factory)
