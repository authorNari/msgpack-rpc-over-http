# require 'celluloid'
require 'httpclient'
require 'forwardable'

module MessagePack
  module RPCOverHTTP

    # Cliet for MessagePack-RPC over HTTP.
    class Client
      extend Forwardable

      HEADER = {"Content-Type" => 'application/x-msgpack'}

      def initialize(url, options={})
        @url = url
        @client = HTTPClient.new
        @reqtable = {}
        @seqid = 0
      end

      def_delegators(:@client,
        :connect_timeout, :send_timeout, :receive_timeout, :debug_dev=)

      # call-seq:
      #   call(symbol, *args) -> result of remote method
      #
      # Calls remote method.
      # This method is same as call_async(method, *args).value
      def call(method, *args)
        return send_request(method, args)
      end

      # call-seq:
      #   call_async(symbol, *args) -> Celluloid::Future
      #
      # Calls remote method asynchronously.
      # This method is non-blocking and returns Future.
      def call_async(method, *args)
        require 'celluloid'
        return Celluloid::Future.new{ send_request(method, args) }
      end

      # call-seq:
      #   callback(symbol, *args) {|res, err| } -> Celluloid::Future
      #
      # Calls remote method asynchronously.
      # The callback method is called with Future when the result is reached.
      # `err' is assigned a instance of RemoteError or child if res is nil.
      def callback(method, *args, &block)
        require 'celluloid'
        return Celluloid::Future.new do
          begin
            block.call(send_request(method, args))
          rescue RemoteError => ex
            block.call(nil, ex)
          end
        end
      end

      # call-seq:
      #   stream(symbol, *args) {|chunk| }
      #
      # Calls remote method with streaming.
      # Remote method have to return a chunked response.
      def stream(method, *args, &block)
        data = create_request_body(method, args)
        @client.post_content(@url, :body => data, :header => HEADER) do |chunk|
          begin
            block.call(get_result(chunk))
          rescue RemoteError => ex
            block.call(nil, ex)
          end
        end
      end

      # call-seq:
      #   stream_async(symbol, *args) {|chunk| } -> Celluloid::Future
      #
      # Calls remote method asynchronously with streaming.
      def stream_async(method, *args, &block)
        require 'celluloid'
        return Celluloid::Future.new do
          stream(method, *args, &block)
        end
      end

      private
      def send_request(method, param)
        data = create_request_body(method, param)
        body = @client.post_content(@url, :body => data, :header => HEADER)
        return get_result(body)
      end

      def create_request_body(method, param)
        method = method.to_s
        msgid = @seqid
        @seqid += 1
        @seqid = 0 if @seqid >= (1 << 31)
        data = [REQUEST, msgid, method, param].to_msgpack
      end

      def get_result(body)
        type, msgid, err, res = MessagePack.unpack(body)
        raise "Unknown message type #{type}" if type != RESPONSE

        if err.nil?
          return res
        else
          raise RemoteError.create(err, res)
        end
      end
    end
  end
end
