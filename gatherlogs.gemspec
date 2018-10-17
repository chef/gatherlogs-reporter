# -*- encoding: utf-8 -*-
# stub: gatherlogs 0.1.6 ruby lib

Gem::Specification.new do |s|
  s.name = "gatherlogs".freeze
  s.version = "0.1.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "TODO: Set to 'http://mygemserver.com'" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Will Fisher".freeze]
  s.date = "2018-10-17"
  s.description = "Inspec profiles for detecting issues from gatherlog output".freeze
  s.email = ["wfisher@chef.io".freeze]
  s.executables = ["check_logs".freeze]
  s.files = [".gitignore".freeze, "Gemfile".freeze, "Gemfile.lock".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "VERSION".freeze, "bin/check_logs".freeze, "bin/console".freeze, "bin/setup".freeze, "completions/check_logs.zsh".freeze, "gatherlogs.gemspec".freeze, "lib/gatherlogs.rb".freeze, "lib/gatherlogs/cli.rb".freeze, "lib/gatherlogs/product.rb".freeze, "profiles/automate/README.md".freeze, "profiles/automate/controls/basic.rb".freeze, "profiles/automate/controls/issues.rb".freeze, "profiles/automate/inspec.yml".freeze, "profiles/automate2/README.md".freeze, "profiles/automate2/controls/basic.rb".freeze, "profiles/automate2/controls/issues.rb".freeze, "profiles/automate2/inspec.yml".freeze, "profiles/automate2/libraries/.gitkeep".freeze, "profiles/chef-backend/README.md".freeze, "profiles/chef-backend/controls/basic.rb".freeze, "profiles/chef-backend/inspec.yml".freeze, "profiles/chef-server/README.md".freeze, "profiles/chef-server/controls/basic.rb".freeze, "profiles/chef-server/controls/drbd.rb".freeze, "profiles/chef-server/controls/issues.rb".freeze, "profiles/chef-server/controls/push_jobs_issues.rb".freeze, "profiles/chef-server/controls/reporting_issues.rb".freeze, "profiles/chef-server/inspec.yml".freeze, "profiles/common/README.md".freeze, "profiles/common/controls/basic.rb".freeze, "profiles/common/inspec.yml".freeze, "profiles/glresources/README.md".freeze, "profiles/glresources/inspec.yml".freeze, "profiles/glresources/libraries/.gitkeep".freeze, "profiles/glresources/libraries/common_logs.rb".freeze, "profiles/glresources/libraries/disk_usage.rb".freeze, "profiles/glresources/libraries/installed_packages.rb".freeze, "profiles/glresources/libraries/log_analysis.rb".freeze, "profiles/glresources/libraries/platform_version.rb".freeze, "profiles/glresources/libraries/service_status.rb".freeze, "profiles/glresources/libraries/sysctl_a.rb".freeze]
  s.homepage = "https://github.com/teknofire/gatherlogs-inspec-profiles".freeze
  s.rubygems_version = "2.7.6".freeze
  s.summary = "Inspec profiles for detecting issues from gatherlog output".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.16"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_development_dependency(%q<version>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<paint>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<mixlib-shellout>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<clamp>.freeze, [">= 0"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.16"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_dependency(%q<version>.freeze, [">= 0"])
      s.add_dependency(%q<paint>.freeze, [">= 0"])
      s.add_dependency(%q<mixlib-shellout>.freeze, [">= 0"])
      s.add_dependency(%q<clamp>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.16"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<version>.freeze, [">= 0"])
    s.add_dependency(%q<paint>.freeze, [">= 0"])
    s.add_dependency(%q<mixlib-shellout>.freeze, [">= 0"])
    s.add_dependency(%q<clamp>.freeze, [">= 0"])
  end
end
