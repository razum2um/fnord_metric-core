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

  s.add_dependency "sinatra", ">= 1.2.6"
  s.add_dependency "redis", ">= 2.2.2"
  s.add_dependency "eventmachine"
  s.add_dependency "websocket-rack", "0.4.0"
  s.add_dependency "em-hiredis", ">= 0.1.1"
  s.add_dependency "json"
  s.add_dependency "i18n"
  s.add_dependency "haml"
  s.add_dependency "rack"
  s.add_dependency "rack-test"
  s.add_dependency "yajl-ruby"
  s.add_dependency "thin", ">= 1.3.0"
  s.add_dependency "activesupport"

  s.add_development_dependency "delorean"
  s.add_development_dependency "rspec", "~> 2.8.0"
  s.add_development_dependency "shoulda"
  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "rake"
end
