class SysctlA < Inspec.resource(1)
  name 'sysctl_a'
  desc 'Parse the sysctl_a config'

  def initialize(filename = 'sysctl_a.txt')
    @content = parse_sysctl(read_content(filename))
  end

  def method_missing(name)
    @content[name.to_sym]
  end

  def exists?
    !@content.empty?
  end

  private

  def parse_sysctl(content)
    data = {}
    content.each_line do |line|
      matched = line.match /^\s*([^=]*?)\s*=\s*(.*?)\s*$/
      next if matched.nil?

      full, name, value = *matched # [1], matched[0]

      # change . to _ because rspec `its('vm.foo')`` will try to call method
      # foo on object vm
      data[name.tr('.', '_').to_sym] = value
    end

    data
  end

  def read_content(filename)
    f = inspec.file(filename)
    if f.file?
      f.content
    else
      ''
    end
  end
end
