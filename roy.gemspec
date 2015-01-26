# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'roy/version'

Gem::Specification.new do |spec|
  spec.name          = "roy"
  spec.version       = Roy::VERSION
  spec.authors       = ["Anthony Leak"]
  spec.email         = ["anthony.leak@gmail.com"]
  spec.summary       = %q{Roy - Just a super guy.}
  spec.description   = %q{We all love Roy.}
  spec.homepage      = "https://www.github.com/aleak/roy"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_development_dependency "pry", '~> 0.10'
  spec.add_development_dependency "pry-byebug", '~> 2.0'
  spec.add_development_dependency "rspec", '~> 2.12'

  spec.add_runtime_dependency 'aws-sdk-v1', '~> 1.61'
  spec.add_runtime_dependency 'activesupport', '~> 4.2'
  spec.add_runtime_dependency 'dotenv', '~> 1.0'
  spec.add_runtime_dependency 'thor', '~> 0.19'

end
