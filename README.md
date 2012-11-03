# MessagePack-RPC over HTTP (Ruby)

This library provides [MessagePack-RPC](https://github.com/msgpack/msgpack-rpc) via HTTP as XML-RPC.
The original MessagePack-RPC Server in Ruby is not good in some cases.
It doesn't scale. It's incompatible with Thread. There is no decent termination...

We alreadly have various high perfomance HTTP servers.
We can use these in MessagePack-RPC over HTTP.

**CAUTION**

There is no compatibility with other implementation of normal MessagePack-RPC (not over HTTP).
So you can not connect a normal RPC client to a RPC server over HTTP.

## Usage

**Server**

confir.ru:
```ruby
require 'msgpack-rpc-over-http'
class MyHandler
  def add(x,y) return x+y end
end

run MessagePack::RPCOverHTTP::Server.app(MyHandler.new)
```

rackup:
```zsh
% rackup config.ru -s thin
>> Thin web server (v1.5.0 codename Knife)
>> Maximum connections set to 1024
>> Listening on 0.0.0.0:9292, CTRL+C to stop
```

**Client**

client.rb:
```ruby
require 'msgpack-rpc-over-http'
c = MessagePack::RPCOverHTTP::Client.new("http://0.0.0.0:9292/")
result = c.call(:add, 1, 2)  #=> 3
```

## Extended futures

Support streaming response via Chunked Transfer-Encoding.

```ruby
# server side
class Handler
  include MessagePack::RPCOverHTTP::Server::Streamer
  def log
    return stream do
      File.open('/var/log/syslog') do |f|
        while line = f.gets.chomp
          # write a chunked data
          chunk(line)
        end
      end
    end
  end
end

# client
client = MessagePack::RPCOverHTTP::Client.new("http://0.0.0.0:80/")
client.stream do |line|
  p line # => "Nov 3 ..."
end
```

## Installation

Add this line to your application's Gemfile:

    gem 'msgpack-rpc-over-http'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install msgpack-rpc-over-http

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
