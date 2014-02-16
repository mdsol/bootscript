# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bootscript/version'

Gem::Specification.new do |spec|
  spec.name          = "bootscript"
  spec.version       = Bootscript::VERSION
  spec.authors       = ["Benton Roberts"]
  spec.email         = ["broberts@mdsol.com"]
  spec.description   = %q{Constructs a self-extracting archive, wrapped in a script, for securely initializing cloud systems}
  spec.summary       = %q{Constructs a self-extracting archive, wrapped in a script, for securely initializing cloud systems}
  spec.homepage      = "http://github.com/mdsol/bootscript"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "erubis"
  spec.add_dependency "minitar"
  spec.add_dependency "rubyzip"
  spec.add_dependency "json"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "ZenTest"
  spec.add_development_dependency "yard"
end
