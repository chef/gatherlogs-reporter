lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

gem_version = File.read('../VERSION') if File.exist?('../VERSION')
# when building the gem in hab the version file gets copied into the local dir
gem_version ||= File.read('VERSION') if File.exist?('VERSION')

Gem::Specification.new do |spec|
  spec.name          = 'gatherlogs_service'
  spec.version       = gem_version
  spec.authors       = ['Will Fisher']
  spec.email         = ['wfisher@chef.io']
  spec.license       = 'Apache-2.0'
  spec.summary       = 'Service to generate reports for gather-logs'
  spec.description   = 'Sinatra app to generate reports for gather-logs'
  spec.homepage      = 'https://github.com/teknofire/grese'

  # Prevent pushing this gem. To allow pushes either set the 'allowed_push_host'
  # or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  spec.files = %w[ VERSION README.md Rakefile LICENSE gatherlogs_service.gemspec
                   Gemfile Gemfile.lock] + Dir.glob(
                     '{bin,lib}/**/*', File::FNM_DOTMATCH
                   ).reject { |f| File.directory?(f) }
  if ENV['BUILD_GEM']
    spec.bindir        = 'bin'
    spec.executables   = %w[grese]
  end
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.1.4'
  spec.add_development_dependency 'rake', '~> 13.1'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
  spec.add_dependency 'mixlib-shellout', '~> 2.4'
  spec.add_dependency 'puma'
  spec.add_dependency 'sinatra', '~> 2.0'
  spec.add_dependency 'string_utf8', '~> 0.1'
  spec.add_dependency 'zendesk_api'
end
