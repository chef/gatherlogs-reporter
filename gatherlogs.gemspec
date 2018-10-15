
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "gatherlogs/version"

Gem::Specification.new do |spec|
  spec.name          = "gatherlogs"
  spec.version       = Gatherlogs::VERSION
  spec.authors       = ["Will Fisher"]
  spec.email         = ["wfisher@chef.io"]

  spec.summary       = %q{Inspec profiles for detecting issues from gatherlog output}
  spec.description   = %q{Inspec profiles for detecting issues from gatherlog output}
  spec.homepage      = "https://github.com/teknofire/gatherlogs-inspec-profiles"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = %w{ check_logs gatherlogs_report.rb }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency "paint"
  spec.add_dependency "mixlib-shellout"
  spec.add_dependency "clamp"
end
