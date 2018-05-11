class DiskUsage < Inspec.resource(1)
  name 'disk_usage'
  desc 'check for issues with disk usage'

  attr_accessor :content
  def initialize
    @content = parse_mounts(read_content)

  end

  def mount(name)
    @content[name]
  end

  private

  def parse_mounts(input)
    diskusage = []
    lines = input.split("\n")
    lines.delete_at(0)
    lines.each do |line|
      line.gsub!(/\s+/, " ")
      diskusage << line.split(" ")
    end

    normalize_output(diskusage)
  end

  # df may split the lines into two separate ones if the device name is long
  # we need to join them back together
  def normalize_output(data)
    output = {}

    while !data.empty?
      row = data.shift
      normalized_row = row.size == 1 ? row + data.shift : row;
      device, size, used, available, used_percent, mount = normalized_row
      output[mount] = DiskUsageItem.new(mount, {:device=>device, :size=>size.to_i, :used=>used.to_i, :available=>available.to_i, :used_percent=>used_percent.to_i, :mount=>mount})
    end

    output
  end

  def read_content
    filename = 'df_h.txt'
    f = inspec.file(filename)
    if f.file?
      f.content
    else
      raise Inspec::Exceptions::ResourceSkipped, "Can't read #{filename}"
    end
  end
end

class DiskUsageItem
  def initialize(name, args)
    @name = name
    @content = args
  end

  def method_missing(item)
    @content[item.to_sym] if @content.has_key?(item.to_sym)
  end

  def to_s
    "\"#{@name}\" disk_usage"
  end
end
