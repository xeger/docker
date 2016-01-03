# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'docker/version'

Gem::Specification.new do |spec|
  spec.name          = "docker"
  spec.version       = Docker::VERSION
  spec.authors       = ["Tony Spataro"]
  spec.email         = ["xeger@xeger.net"]

  spec.summary       = %q{Docker CLI wrapper.}
  spec.description   = %q{Provides an OOP interface to docker without relying on its HTTP API.}
  spec.homepage      = "https://github.com/xeger/docker"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "backticks", "~> 0.3"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
