class CpuInfo < Inspec.resource(1)
  name 'cpu_info'
  desc 'Read in contents of cpuinfo.txt file for cpu info'

  attr_accessor :content

  def initialize
    @content = read_content
  end

  def exists?
    cpu_file.exist?
  end

  def total
    return 0 if content.nil?
    cpus = content.lines.select { |l| l.match?(/model name/) }
    cpus.length
  end

  def model_name
    return 'Unknown' if content.nil?
    cpus = content.lines.select { |l| l.match?(/model name/) }
    cpus.first.split(/\s+:\s+/).last
  end

  def cpu_file
    if inspec.file('cpuinfo.txt').exist?
      inspec.file('cpuinfo.txt')
    elsif inspec.file('proc/cpuinfo').exist?
      inspec.file('proc/cpuinfo')
    else
      inspec.file('invalid')
    end
  end

  def read_content
    cpu_file.content if exists?
  end
end
