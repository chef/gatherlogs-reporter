class InstalledPackages < Inspec.resource(1)
  name 'installed_packages'
  desc 'attempt to detect the chef product'

  attr_accessor :content

  def initialize(name)
    @content ||= read_content
    @package_name = name
  end

  def exist?
    content.match?(@package_name)
  end
  alias_method :exists?, :exist?

  def version
    package_version(@package_name)
  end

  private

  # This is an ugly hack to get around a bug where other custom resources
  # are not available inside a custom resource.
  def platform_version
    self.class.__resource_registry['platform_version'].new(inspec, 'platform_version')
  end

  def package_version(name)
    case platform_version.os
    # case :rhel
    when :rhel
      result = content.match(/#{name}-(\d+\.\d+\.\d+)-\d+.\w.\w/)
      result[1] unless result.nil?
    else
      raise Inspec::Exceptions::ResourceSkipped, "installed_packages currently doesn't support #{platform_version.os.inspect}"
    end
  end

  def read_content
    f = inspec.file('installed-packages.txt')
    if f.file?
      f.content
    else
      raise Inspec::Exceptions::ResourceSkipped, "Can't read installed-packages.txt"
    end
  end
end
