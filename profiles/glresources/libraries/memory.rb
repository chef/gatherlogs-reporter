class Memory < Inspec.resource(1)
  name 'memory'
  desc 'Read in contents of free_m.txt file for mem info'

  attr_accessor :content

  def initialize
    @content = read_content
    @mem = {}
    @swap = {}
  end

  def total_mem
    mem['total']
  end

  def free_mem
    available_mem
  end

  def available_mem
    if mem.key?('available')
      mem['available']
    else
      total_mem.to_i - used_mem.to_i + buffers_mem.to_i + cached_mem.to_i
    end
  end

  def cached_mem
    mem['cached']
  end

  def buffers_mem
    mem['buffers']
  end

  def used_mem
    mem['used']
  end

  def total_swap
    swap['total']
  end

  def free_swap
    swap['free']
  end

  def mem
    if (m = content.match(/^Mem:\s+(.*)$/))
      values = m[1].split(/\s+/).map(&:to_i)

      if (h = content.match(/^\s+(total\s+.*)$/))
        headers = h[1].split(/\s+/)

        @mem = headers.zip(values).to_h
        if @mem.key?('buff/cache')
          @mem['cached'] = @mem['buff/cache']
          @mem['buffers'] = 0
        end
      end
    end

    @mem
  end

  def swap
    if (m = content.match(/^Swap:\s+(.*)$/))
      values = m[1].split(/\s+/).map(&:to_i)
      if (h = content.match(/^\s+(total\s+.*)$/))
        headers = h[1].split(/\s+/)
        @swap = headers.zip(values).to_h
      end
    end

    @swap
  end

  def mem_file
    if inspec.file('free_m.txt').exist?
      inspec.file('free_m.txt')
    elsif inspec.file('free-m.txt').exist?
      inspec.file('free-m.txt')
    else
      inspec.file('bogusfile.notfound')
    end
  end

  def exists?
    mem_file.exist?
  end

  def read_content
    return nil unless mem_file.exist?

    mem_file.content
  end
end
