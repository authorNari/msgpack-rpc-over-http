module MessagePack
  module RPCOverHTTP
    class Server

      # Rack Middleware that packs a result of a handler method and
      # create a HTTP Responce.
      class ResponsePacker
        def initialize(dispatcher)
          @dispatcher = dispatcher
        end

        def call(env)
          res = Rack::Response.new
          res["Content-type"] = "text/plain"
          msgid = env['msgpack-rpc.msgid']

          body = @dispatcher.call(env)
          if body.is_a?(Streamer::Body)
            body.msgid = msgid
            res.body = body
            return [res.status.to_i, res.header, body]
          else
            res.write self.class.pack(msgid, nil, body)
            return res.finish
          end
        rescue RPCOverHTTP::RemoteError => ex
          res.write self.class.pack(msgid, ex.class.name, ex.message)
          return res.finish
        rescue ::RuntimeError => ex
          res.write(self.class.pack(
              msgid, RPCOverHTTP::RuntimeError.name, ex.message))
          return res.finish
        end

        def self.pack(msgid, error, result)
          return MessagePack.pack([RESPONSE, msgid, error, result])
        end
      end
    end
  end
end
