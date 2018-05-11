class PlatformVersion < Inspec.resource(1)
  name 'platform_version'
  desc 'Attempt to detect the current platform from the gatherlogs'

  attr_accessor :content
  def initialize
    @content = read_content 
  end

  def rhel?
    content.match?('Red Hat Enterprise Linux Server')
  end

  def rhel_version
    result = content.match(/Red Hat Enterprise Linux Server release (\d\.\d)/)

    result[1] unless result.nil?
  end

  def os
    return :rhel if rhel?
  end

  def os_version
    return rhel_version if rhel?
  end

  private

  def read_content
    f = inspec.file('platform_version.txt')
    if f.file?
      f.content 
    else
      raise Inspec::Exceptions::ResourceSkipped, "Can't read platform_version.txt"
    end
  end
end
