# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fnord_metric/core/version'

Gem::Specification.new do |spec|
  spec.name          = "fnord_metric-core"
  spec.version       = FnordMetric::Core::VERSION
  spec.authors       = ["Vlad Bokov"]
  spec.email         = ["razum2um@mail.ru"]
  spec.description   = %q{extracted FnordMetric core part}
  spec.summary       = %q{extracted FnordMetric core part}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "sinatra", ">= 1.2.6"
  spec.add_dependency "redis", ">= 2.2.2"
  spec.add_dependency "eventmachine"
  spec.add_dependency "websocket-rack", "0.4.0"
  spec.add_dependency "em-hiredis", ">= 0.1.1"
  spec.add_dependency "json"
  spec.add_dependency "i18n"
  spec.add_dependency "haml"
  spec.add_dependency "rack"
  spec.add_dependency "rack-test"
  spec.add_dependency "yajl-ruby"
  spec.add_dependency "thin", ">= 1.3.0"
  spec.add_dependency "activesupport"

  spec.add_development_dependency "delorean"
  spec.add_development_dependency "rspec", "~> 2.8.0"
  spec.add_development_dependency "shoulda"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
