#\ -s thin
$LOAD_PATH.unshift(File.expand_path("./../lib", File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'msgpack-rpc-over-http'
require 'helper'

run MessagePack::RPCOverHTTP::Server.app(MockHandler.new)
