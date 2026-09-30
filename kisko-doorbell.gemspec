lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "kisko/doorbell/version"

Gem::Specification.new do |spec|
  spec.name          = "kisko-doorbell"
  spec.version       = Kisko::Doorbell::VERSION
  spec.authors       = ["Matias Korhonen"]
  spec.email         = ["matias@kiskolabs.com"]

  spec.summary       = "Use rtl_433 to notify Slack when a doorbell rings"
  spec.description = "Listen for a doorbell signal using rtl_433 and an RTL-SDR receiver " \
                     "and notify Slack when the right doorbell rings"
  spec.homepage      = "https://github.com/kiskolabs/kisko-doorbell"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.6"

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kiskolabs/kisko-doorbell"
  spec.metadata["changelog_uri"] = "https://github.com/kiskolabs/kisko-doorbell"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    tracked_files = `git ls-files -z`.split("\x0")
    tracked_files.grep_v(%r{^(test|spec|features)/}).select { |file| File.file?(file) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "bigdecimal", "~> 3.1"
  spec.add_dependency "honeybadger", "~> 4.0"
  spec.add_dependency "slack-ruby-client", "~> 0.14"
  spec.add_dependency "sucker_punch", "~> 2.0"
  spec.add_dependency "tty-logger", "~> 0.1"
  spec.add_dependency "tty-which", "~> 0.4"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "pry", "~> 0.12"
  spec.add_development_dependency "rake", "~> 13.2"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rubocop", "~> 1.82.1"
end
