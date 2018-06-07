class CommonLogs < Inspec.resource(1)
  name 'common_logs'
  desc 'lists of common log files for various services'

  def erchef(&block)
    files = %w{ erchef.log current crash.log requests.log }
    if block_given?
      files.each { |f| yield f }
    else
      files
    end
  end
end
