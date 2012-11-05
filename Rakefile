#!/usr/bin/env rake
require "bundler/setup"
Bundler.require(:default, :development)
require "bundler/gem_tasks"

task :default do
  sh "/usr/bin/env ruby test/run-test.rb"
end
