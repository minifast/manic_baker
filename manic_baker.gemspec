# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'manic_baker/version'

Gem::Specification.new do |spec|
  spec.name          = "manic_baker"
  spec.version       = ManicBaker::VERSION
  spec.authors       = ["Doc Ritezel"]
  spec.email         = ["doc@minifast.co"]
  spec.description   = %q{Makes Joyent less manic}
  spec.summary       = %q{Stop calling the Ghostbusters just because you don't like my music, mom}
  spec.homepage      = "https://github.com/minifast/manic_baker"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split("\n")
  spec.executables   = `git ls-files -- bin`.split("\n").map { |f| File.basename(f) }
  spec.test_files    = `git ls-files -- spec`.split("\n")
  spec.require_paths = ["lib"]

  spec.add_dependency "fog"
  spec.add_dependency "soloist"

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "guard-bundler"
  spec.add_development_dependency "gem-release"
end
