require 'msgpack'
require_relative "msgpack/rpc_over_http/version"
require_relative "msgpack/rpc_over_http/error"
require_relative "msgpack/rpc_over_http/server"
require_relative "msgpack/rpc_over_http/client"

module MessagePack
  module RPCOverHTTP
    REQUEST  = 0    # [0, msgid, method, param]
    RESPONSE = 1    # [1, msgid, error, result]
    NOTIFY   = 2    # [2, method, param]

    NO_METHOD_ERROR = 0x01;
    ARGUMENT_ERROR  = 0x02;
  end
end
