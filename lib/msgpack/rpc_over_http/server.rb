require 'rack'
require 'rack/builder'
require_relative 'server/dispatcher'
require_relative 'server/request_unpacker'
require_relative 'server/response_packer'
require_relative 'server/streamer'

module MessagePack
  module RPCOverHTTP
    class Server

      # Retruns the application for MessagePack-RPC.
      # It's create with Rack::Builder
      def self.app(handler, factory = nil)
        return Rack::Builder.app do
          use Rack::Chunked
          use RequestUnpacker, factory
          use ResponsePacker, factory
          use Dispatcher
          run handler
        end
      end
    end
  end
end
