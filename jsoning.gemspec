# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jsoning/version'

Gem::Specification.new do |spec|
  spec.name          = "jsoning"
  spec.version       = Jsoning::VERSION
  spec.authors       = ["Adam Pahlevi"]
  spec.email         = ["adam.pahlevi@gmail.com"]

  spec.summary       = %q{Turns any of your everyday ruby objects to json formats, the way you always want it}
  spec.description   = %q{Turning object into json can sometimes be frustrating. With Jsoning, you could turn your
                            everyday ruby object into JSON, very easily. It should work with
                            any Ruby object there is. Kiss good bye to complexity!}
  spec.homepage      = "http://github.com/saveav/jsoning"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"
end
