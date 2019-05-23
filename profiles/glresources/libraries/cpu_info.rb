class CpuInfo < Inspec.resource(1)
  name 'cpu_info'
  desc 'Read in contents of cpuinfo.txt file for cpu info'

  attr_accessor :content

  # This is needed because some arches like POWER8 uses a cpu header
  # instead of model name like Intel systems.
  CPU_NAME_REGEXP = /model name|cpu\s+:/.freeze

  def initialize
    @content = read_content
  end

  def exists?
    cpu_file.exist?
  end

  def cpus
    @cpus ||= content.select { |l| l.match?(CPU_NAME_REGEXP) }.map(&:strip)
  end

  def total
    cpus.length
  end

  def model_name
    info = cpus.first.split(/\s+:\s+/).last unless cpus.empty?
    info ||= 'Unknown'

    info
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
    return [] unless exists?

    cpu_file.content.lines
  end
end
