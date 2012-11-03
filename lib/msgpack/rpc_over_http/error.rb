module MessagePack

  ##
  ## MessagePack-RPCOverHTTP Exception
  ##
  #
  #  RemoteError
  #  |
  #  +-- RuntimeError
  #  |
  #  +-- (user-defined errors)
  #
  module RPCOverHTTP
    class RemoteError < StandardError
      def initialize(code, *data)
        @code = code.to_s
        @data = data
        super(@data.shift || @code)
      end

      attr_reader :code
      attr_reader :data

      def self.create(code, data)
        error_class = constantize(code)
        if error_class < RemoteError
          error_class.new(code, *data)
        else
          self.new(code, *data)
        end
      end

      private
      def self.constantize(name)
        return name.split("::").inject(Object) do |memo, i|
          memo.const_get(i)
        end
      end
    end

    class RuntimeError < RemoteError
    end
  end
end
