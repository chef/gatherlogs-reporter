class LogAnalysis < Inspec.resource(1)
  name 'log_analysis'
  desc 'Parse log files to find issues'

  attr_accessor :logfile, :grep_expr, :messages
  def initialize(log, expr, options = {})
    @options = options || {}
    @grep_expr = expr
    @logfile = log
    @messages = read_content
  end

  def hits
    @messages.count
  end

  def first
    @messages.first
  end

  def last
    @messages.last
  end

  def empty?
    @messages.empty?
  end

  # this is for use in the matchers so we can get a better UX with the latest
  # log entry text showing up in the verbose output
  def last_entry
    last || ''
  end

  def content
    @messages
  end

  def summary
    <<~EOS.strip
      Found #{hits} messages about '#{grep_expr}'
      Last entry: #{last_entry}
    EOS
  end

  def exists?
    hits > 0
  end

  def log_exists?
    inspec.file(logfile).exist?
  end

  def to_s
    "log_analysis(#{logfile}, #{grep_expr})"
  end

  private

  def read_content
    cmd = []

    return [] unless File.exist?(logfile)

    if inspec.os.family == 'darwin'
      grep_flag = '-E'
    else
      grep_flag = '-P'
    end


    cmd << if @options[:a2service]
             "grep -i '#{@options[:a2service]}' #{logfile} | grep -i #{grep_flag} '#{grep_expr}'"
           else
             "grep -i #{grep_flag} '#{grep_expr}' #{logfile}"
           end

    command = inspec.command(cmd.join(' | '))

    if command.exit_status > 1
      raise "#{cmd.join(' | ')} exited #{command.exit_status}\nERROR MSG: #{command.stderr}"
    end

    command.stdout.split("\n")
  end
end
