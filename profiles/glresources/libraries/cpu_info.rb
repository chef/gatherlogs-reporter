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
    inspec.file('cpuinfo.txt')
  end

  def read_content
    cpu_file.content if exists?
  end
end
