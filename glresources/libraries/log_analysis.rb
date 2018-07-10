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
    <<-EOS
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

    if @options[:a2service]
      cmd << "grep '#{@options[:a2service]}' #{logfile}"
      cmd << "egrep '#{grep_expr}'"
    else
      cmd << "egrep '#{grep_expr}' #{logfile}"
    end

    inspec.command(cmd.join(' | ')).stdout.split("\n")
  end
end
