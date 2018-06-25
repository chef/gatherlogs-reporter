class InstalledPackages < Inspec.resource(1)
  name 'installed_packages'
  desc 'attempt to detect the chef product'

  def initialize(name)
    # This is needed because automate-ctl gatherlogs doesn't include a
    # `installed-packages.txt`
    # Also, the method used for exist? on Automate is not ideal as another
    # product could include version-manifest.json and would give a false postive
    # if requesting the automate package version.
    if name == 'automate'
      filename = 'opt/delivery/version-manifest.json'
      @package = AutomateVersionManifestJson.new(name, read_content(filename))
    else
      filename = 'installed-packages.txt'
      @package = InstalledPackagesTxt.new(name, read_content(filename), platform_version.os)
    end
  end

  def exist?
    @package.exist?
  end
  alias_method :exists?, :exist?

  def version
    @package.version
  end

  private

  def read_content(filename)
    f = inspec.file(filename)
    if f.file?
      f.content
    else
      nil
    end
  end

  # This is an ugly hack to get around a bug where other custom resources
  # are not available inside a custom resource.
  def platform_version
    self.class.__resource_registry['platform_version'].new(inspec, 'platform_version')
  end
end

class InstalledPackagesTxt
  attr_accessor :content, :version

  def initialize(name, packages_content, os)
    @package_name = name
    @content = packages_content
    @version = package_version(os)
  end

  def exist?
    content && content.match?(@package_name)
  end

  private

  def package_version(os)
    return if os.nil?
    return unless exist?

    case os.to_sym
    when :rhel
      result = content.match(/#{@package_name}-(\d+\.\d+\.\d+)-\d+.\w.\w/)
      result[1] unless result.nil?
    when :ubuntu
      result = content.match(/#{@package_name}\s+(\d+\.\d+\.\d+)/)
      result[1] unless result.nil?
    else
      nil
    end
  end
end

class AutomateVersionManifestJson
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
