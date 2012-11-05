module MessagePack
  module RPCOverHTTP
    class Server

      # Rack Middleware that unpacks a serialized string in a HTTP
      # request.
      class RequestUnpacker
        def initialize(app)
          @app = app
        end

        def call(env)
          req = Rack::Request.new(env)
          if (error = check_request(req))
            return error
          end

          unpack(env, req.body.read)
          return @app.call(env)
        end

        private
        def check_request(req)
          if req.request_method != "POST"
            return [
              405, # Method Not Allowed
              {'Content-Type' => 'text/plain'},
              ["Only POST is allowed"]
            ]
          end

          if req.media_type != "application/x-msgpack"
            return [
              400, # Bad Request
              {'Content-Type' => 'text/plain'},
              ["Only text/plain is allowed #{req.content_type}"]
            ]
          end

          if req.content_length.to_i <= 0
            return [
              411, # Length Required
              {'Content-Type' => 'text/plain'},
              ["Missing Content-Length"]
            ]
          end

          return nil
        end

        def unpack(env, body)
          msg = MessagePack.unpack(body)
          env['msgpack-rpc.type'] = msg[0]
          case msg[0]
          when REQUEST
            env['msgpack-rpc.msgid'] = msg[1]
            env['msgpack-rpc.method'] = msg[2].to_sym
            env['msgpack-rpc.params'] = msg[3]
          when NOTIFY
            env['msgpack-rpc.method'] = msg[1].to_sym
            env['msgpack-rpc.params'] = msg[2]
          else
            raise "unknown message type #{msg[0]}"
          end
        end
      end
    end
  end
end
