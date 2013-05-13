module MessagePack
  module RPCOverHTTP
    class Server

      # Dispatcher of user-defined handler.
      class Dispatcher
        def initialize(handler, accept=handler.public_methods)
          @handler = handler
          @accept = accept
        end

        def call(env)
          method = env['msgpack-rpc.method']
          params = env['msgpack-rpc.params']
          unless @accept.include?(method)
            raise NoMethodError, "method `#{method}' is not accepted"
          end

          return @handler.__send__(method, *params)
        end
      end
    end
  end
end
