class CommonLogs < Inspec.resource(1)
  name 'common_logs'
  desc 'lists of common log files for various services'

  def erchef(&block)
    files = %w{ erchef.log current crash.log requests.log requests.log.1 requests.log.2 requests.log.3 requests.log.4 requests.log.5 requests.log.6 requests.log.7 requests.log.8 requests.log.9 }
    if block_given?
      files.each { |f| yield f }
    else
      files
    end
  end
end
