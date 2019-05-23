class DiskUsage < Inspec.resource(1)
  name 'disk_usage'
  desc 'check for issues with disk usage'

  attr_accessor :content
  def initialize
    @content = parse_mounts(read_content)
  end

  def mount(name)
    @content[name] || DiskUsageItem.new
  end

  def exists?(name)
    mount(name).exists?
  end

  def each
    @content.keys.each do |mount|
      yield @content[mount]
    end
  end

  private

  # need to normalize the filesize
  def to_filesize(size)
    # size = '0' if size.nil?

    units = {
      'B' => 1 / (1024 * 1024),
      'K' => 1 / 1024,
      'M' => 1,
      'G' => 1024,
      'T' => 1024 * 1024
    }

    unit = size[-1]
    unit = 'B' unless units.key?(unit)

    "#{size[0..-1].to_f * units[unit]}M"
  end

  def parse_mounts(input)
    diskusage = []
    lines = input.split("\n")
    lines.delete_at(0)
    lines.each do |line|
      next if line.empty?
      next if line =~ /^df -h$/

      line.gsub!(/\s+/, ' ')
      diskusage << line.split(' ')
    end

    normalize_output(diskusage)
  end

  # df may split the lines into two separate ones if the device name is long
  # we need to join them back together
  def normalize_output(data)
    output = {}

    until data.empty?
      row = data.shift
      normalized_row = row.size == 1 ? row + data.shift : row
      device, size, used, available, used_percent, mount = normalized_row
      output[mount] = DiskUsageItem.new(mount, device: device, size: to_filesize(size), used: to_filesize(used), available: to_filesize(available), used_percent: used_percent.to_i, mount: mount)
    end

    output
  end

  def read_content
    filename = 'df_h.txt'
    f = inspec.file(filename)

    if  f.exist?
      f.content
    else
      ''
    end
  end
end

class DiskUsageItem
  def initialize(name = nil, args = {})
    @name = name
    @content = args
  end

  # rubocop:disable Style/MethodMissingSuper
  def method_missing(item)
    @content[item.to_sym] || nil
  end
  # rubocop:enable Style/MethodMissingSuper

  def respond_to_missing?(item, include_private = false)
    @content.key?(item.to_sym) || super
  end

  def exists?
    !@name.nil?
  end

  def to_s
    "\"#{@name}\" disk_usage"
  end
end
