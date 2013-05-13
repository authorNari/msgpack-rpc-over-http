# -*- encoding: utf-8 -*-
require File.expand_path('../lib/msgpack/rpc_over_http/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Narihiro Nakamura"]
  gem.email         = ["authornari@gmail.com"]
  gem.description   = %q{This library provides MessagePack-RPC via HTTP}
  gem.summary       = %q{This library provides MessagePack-RPC via HTTP}
  gem.homepage      = "https://github.com/authorNari/msgpack-rpc-over-http"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "msgpack-rpc-over-http"
  gem.require_paths = ["lib"]
  gem.version       = MessagePack::RPCOverHTTP::VERSION

  gem.add_runtime_dependency "rack", "~> 1.4.1"
  gem.add_runtime_dependency "msgpack", "~> 0.4.7"
  gem.add_runtime_dependency "celluloid", "~> 0.12.3"
  gem.add_runtime_dependency "httpclient", "~> 2.3.0.1"

  gem.add_development_dependency "thin"
end
