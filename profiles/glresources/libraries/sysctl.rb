class Sysctl < Inspec.resource(1)
  name 'sysctl'
  desc 'Parse the sysctl config'

  def initialize(filename = 'sysctl_a.txt')
    @filename = filename
    @content = parse_sysctl(read_content)
  end

  def method_missing(name)
    @content[name.to_sym] || super
  end

  def respond_to_missing?(name, include_private = false)
    @content.key?(name.to_sym) || super
  end

  def exists?
    sysctl_file.exist?
  end

  private

  def parse_sysctl(content)
    data = {}
    content.each_line do |line|
      matched = line.match(/^\s*([^=]*?)\s*=\s*(.*?)\s*$/)
      next if matched.nil?

      _full, name, value = *matched # [1], matched[0]

      # change . to _ because rspec `its('vm.foo')`` will try to call method
      # foo on object vm
      data[name.tr('.', '_').to_sym] = value
    end

    data
  end

  def sysctl_file
    inspec.file(@filename)
  end

  def read_content
    return '' unless sysctl_file.exist?

    sysctl_file.content
  end
end
