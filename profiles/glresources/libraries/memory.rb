class Memory < Inspec.resource(1)
  name 'memory'
  desc 'Read in contents of free_m.txt file for mem info'

  attr_accessor :content

  def initialize
    @content = read_content
  end

  def total_mem
    mem_line[0].to_i
  end

  def free_mem
    # calculate it like this so it takes into account cached and buffered mem
    total_mem - used_mem + buffers_mem + cached_mem
  end

  def cached_mem
    mem_line[5].to_i
  end

  def buffers_mem
    mem_line[4].to_i
  end

  def used_mem
    mem_line[1].to_i
  end

  def total_swap
    mem_line[0].to_i
  end

  def free_swap
    mem_line[2].to_i
  end

  def mem_line
    m = content.match(/^Mem:\s+(.*)$/)
    return [] if m.nil?
    m[1].split(/\s+/)
  end

  def swap_line
    m = content.match(/^Swap:\s+(.*)$/)
    return [] if m.nil?
    m[1].split(/\s+/)
  end

  def mem_file
    if inspec.file('free_m.txt').exist?
      inspec.file('free_m.txt')
    elsif inspec.file('free-m.txt').exist?
      inspec.file('free-m.txt')
    else
      false
    end
  end

  def exists?
    !!mem_file
  end

  def read_content
    return nil unless mem_file.exist?
    mem_file.content
  end
end
