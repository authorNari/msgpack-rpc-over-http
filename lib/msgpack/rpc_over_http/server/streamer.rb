require 'fiber'

module MessagePack
  module RPCOverHTTP
    class Server

      # Support streaming
      module Streamer
        class Body
          attr_accessor :msgid

          def initialize(&proc)
            @proc = proc
          end

          def each(&block)
            @proc.call(msgid, block)
            return self
          end
        end

        # call-seq:
        #   stream(&writer) -> streamable body
        #
        # Returns a Body object that responds to each.
        # Chunks of body are created with calling chunk() in given block.
        #
        #   def passwd
        #     return stream do
        #       File.open('/etc/passwd') do |file|
        #         while line = file.gets
        #           chunk(file.gets)
        #         end
        #       end
        #     end
        #   end
        def stream(&writer)
          fi = Fiber.new do
            writer.call
          end

          Body.new do |msgid, sender|
            begin
              while true
                chunk = fi.resume
                break unless fi.alive?
                sender.call(ResponsePacker.pack(msgid, nil, chunk))
              end
            rescue RemoteError => ex
              sender.call(ResponsePacker.pack(msgid, ex.class.name, nil))
            rescue ::RuntimeError => ex
              sender.call(ResponsePacker.pack(msgid, RuntimeError.name, nil))
            end
          end
        end

        # call-seq:
        #   chunk(obj)
        #
        # Send a object as chunked data in block of stream().
        def chunk(obj)
          Fiber.yield(obj)
        end
      end
    end
  end
end
