# PROFILES_PATH = File.expand_path('../../profiles', __dir__).freeze

module Gatherlogs
  module Profiles
    PROFILE_PATH = File.expand_path('../../profiles', __dir__).freeze

    def self.list
      find.reject! { |p| %w[common glresources].include?(p) }.sort
    end

    def self.find
      Dir.glob(File.join(PROFILE_PATH, '*/inspec.yml')).map do |p|
        File.basename(File.dirname(p)).gsub('-wrapper', '')
      end
    end

    def self.path(profile)
      path = File.join(PROFILE_PATH, "#{profile}-wrapper")
      return path if File.exist?(path)

      raise "Couldn't find '#{profile}' profile, tried in '#{path}'"
    end
  end
end
