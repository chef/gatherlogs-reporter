class InstalledPackages < Inspec.resource(1)
  name 'installed_packages'
  desc 'attempt to detect the chef product'

  def initialize(name)
    # This is needed because automate-ctl gatherlogs doesn't include a
    # `installed-packages.txt`
    # Also, the method used for exist? on Automate is not ideal as another
    # product could include version-manifest.json and would give a false postive
    # if requesting the automate package version.
    case name
    when 'automate'
      filename = 'opt/delivery/version-manifest.json'
      @package = VersionManifestJson.new(name, read_content(filename))
    when 'chef-backend'
      filename = 'opt/chef-backend/version-manifest.json'
      @package = VersionManifestJson.new(name, read_content(filename))
    when 'automate2'
      filename = 'chef-automate_current_manifest.txt'
      @package = A2ManifestJson.new(name, read_content(filename))
    else
      filename = 'installed-packages.txt'
      @package = InstalledPackagesTxt.new(name, read_content(filename), platform_version.os)
    end
  end

  def exist?
    @package.exist?
  end
  alias exists? exist?

  def version
    @package.version
  end

  private

  def read_content(filename)
    f = inspec.file(filename)
    f.content if f.file?
  end

  # This is an ugly hack to get around a bug where other custom resources
  # are not available inside a custom resource.
  def platform_version
    self.class.__resource_registry['platform_version'].new(inspec, 'platform_version')
  end
end

class InstalledPackagesTxt
  attr_accessor :content, :version

  # rubocop:disable Naming/UncommunicativeMethodParamName
  def initialize(name, packages_content, os)
    @package_name = name
    @content = packages_content
    @version = package_version(os)
  end
  # rubocop:enable Naming/UncommunicativeMethodParamName

  def exist?
    content&.match?(@package_name)
  end

  private

  # rubocop:disable Naming/UncommunicativeMethodParamName
  def package_version(os)
    return if os.nil?
    return unless exist?

    result = case os.to_sym
             when :rhel, :centos
               content.match(/#{@package_name}-(\d+\.\d+\.\d+(~\w+\.\d+)*)-\d+.\w.\w/)
             when :ubuntu
               content.match(/#{@package_name}\s+(\d+\.\d+\.\d+)/)
             end

    result[1] unless result.nil?
  end
  # rubocop:enable Naming/UncommunicativeMethodParamName
end

class VersionManifestJson
  attr_accessor :content, :version

  def initialize(name, packages_content)
    @content = JSON.parse(packages_content)
    @package_name = name
    @version = package_version
  end

  def exist?
    !content.nil?
  end

  private

  def package_version
    content['build_version']
  end
end

class A2ManifestJson
  attr_accessor :content, :version

  def initialize(name, packages_content)
    @package_name = name
    parse_content(packages_content) unless packages_content.nil?
  end

  def parse_content(content)
    # strip the first line from content
    lines = content.lines
    lines.shift
    packages_content = lines.join("\n")

    @content = JSON.parse(packages_content)
    @version = package_version
  end

  def exist?
    !content.nil?
  end

  private

  def package_version
    content['build']
  end
end
