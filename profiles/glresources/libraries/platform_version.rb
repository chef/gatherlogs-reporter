class PlatformVersion < Inspec.resource(1)
  name 'platform_version'
  desc 'Attempt to detect the current platform from the gatherlogs'

  PLATFORM_MATCH = {
    centos: 'CentOS',
    rhel: 'Red Hat Enterprise Linux Server',
    ubuntu: 'Ubuntu'
  }.freeze

  PLATFORM_MATCH.keys.each do |k|
    define_method("#{k}?".to_sym) { |plat| platform_match(plat) }
  end

  attr_accessor :content
  def initialize
    @content = read_content
  end

  def platform_match?(platform)
    return false if content.nil?

    content.match?(PLATFORM_MATCH[platform.to_sym])
  end

  def ubuntu_version
    puts SimpleConfig.new(content).inspect
  end

  def exists?
    platform_file.exist?
  end

  def rhel_version
    result = content.match(/Red Hat Enterprise Linux Server release (\d\.\d)/)

    result[1] unless result.nil?
  end

  def full_info
    # data = TOML.load(content)
    # STDERR.puts data.inspect
    if (m = content.match(/DISTRIB_DESCRIPTION="(.*)"/))
      m[1]
    elsif (m = content.match(/PRETTY_NAME="(.*)"/))
      v = content.match(/VERSION_ID=(.*)/)

      version = v[1].delete('"')
      version ||= ''

      "#{m[1]} (#{version})"
    else
      content.lines.map(&:chomp).join(' ')
    end
  end

  def os
    PLATFORM_MATCH.keys.each do |platform|
      return platform.to_sym if platform_match?(platform)
    end
  end

  def os_version
    return rhel_version if rhel?
  end

  private

  def platform_file
    if inspec.file('etc/os-release').exist?
      inspec.file('etc/os-release')
    elsif inspec.file('platform_version.txt').exist?
      inspec.file('platform_version.txt')
    elsif inspec.file('etc/lsb-release').exist?
      inspec.file('etc/lsb-release')
    else
      inspec.file('invalid')
    end
  end

  def read_content
    unless platform_file.file?
      raise Inspec::Exceptions::ResourceSkipped, "Can't read platform_version.txt"
    end

    platform_file.content
  end
end
