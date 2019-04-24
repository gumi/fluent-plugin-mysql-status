# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fluent/plugin/mysql_status/version'

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-mysql-status"
  spec.version       = Fluent::MySQLStatus::VERSION
  spec.authors       = ["IKUTA Masahito"]
  spec.email         = ["masahito.ikuta@gu3.co.jp"]
  spec.summary       = %q{Fluentd input plugin that monitor status of MySQL Server.}
  spec.description   = spec.summary
  spec.homepage      = "http://github.com/gumi/fluent-plugin-mysql-status"
  spec.license       = "APLv2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "test-unit", ["~> 3.0", "~> 3.1"]

  spec.add_dependency "fluentd", ">= 0.10.55"
  spec.add_dependency "mysql2", "~> 0.5.2"
end
