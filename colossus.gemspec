# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'colossus/version'

Gem::Specification.new do |s|
  s.name          = "colossus"
  s.version       = Colossus::VERSION
  s.authors       = ["antoinelyset"]
  s.email         = ["antoinelyset+github@gmail.com"]
  s.homepage      = "https://github.com/antoinelyset/colossus"
  s.summary       = "Colossus, Web Push & Presence made easy."
  s.description   = "Colossus is a Push and Presence pure Ruby server. It uses Faye internally."

  s.files         = `git ls-files lib`.split("\n")
  s.platform      = Gem::Platform::RUBY
  s.require_paths = ['lib']

  s.add_dependency('faye',         '~> 1.0')
  s.add_dependency('em-synchrony', '~> 1.0')
end
