#\ -s thin

### NOTE: this file is not used with jruby. FIX test/test_client.rb #setup if this file is fixed.

$LOAD_PATH.unshift(File.expand_path("./../lib", File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'msgpack-rpc-over-http'
require 'helper'

run MessagePack::RPCOverHTTP::Server.app(MockHandler.new)
