lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "kisko/doorbell/version"

Gem::Specification.new do |spec|
  spec.name          = "kisko-doorbell"
  spec.version       = Kisko::Doorbell::VERSION
  spec.authors       = ["Matias Korhonen"]
  spec.email         = ["matias@kiskolabs.com"]

  spec.summary       = %q{Use rtl_433 to notify Flowdock when a doorbell rings}
  spec.description   = %q{Listen for a doorbell signal using rtl_433 and an RTL-SDR receiver and notify Flowdock when the right doorbell rings}
  spec.homepage      = "https://github.com/kiskolabs/kisko-doorbell"
  spec.license       = "MIT"

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kiskolabs/kisko-doorbell"
  spec.metadata["changelog_uri"] = "https://github.com/kiskolabs/kisko-doorbell"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "flowdock", "~> 0.7"
  spec.add_dependency "tty-logger", "~> 0.1"
  spec.add_dependency "tty-which", "~> 0.4"
  spec.add_dependency "sucker_punch", "~> 2.0"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.12"
end
