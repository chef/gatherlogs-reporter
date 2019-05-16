class CommonLogs < Inspec.resource(1)
  name 'common_logs'
  desc 'lists of common log files for various services'

  def erchef
    files = %w[erchef.log current crash.log requests.log requests.log.1 requests.log.2 requests.log.3 requests.log.4 requests.log.5 requests.log.6 requests.log.7 requests.log.8 requests.log.9]
    if block_given?
      files.each { |f| yield f }
    else
      files
    end
  end

  def nginx
    files = %w[current error.log access.log internal-chef.access.log]
    if block_given?
      files.each { |f| yield f }
    else
      files
    end
  end

  def solr4
    files = %w[current]
    if block_given?
      files.each { |f| yield f }
    else
      files
    end
  end

  def ss_ontap
    # automate 2 uses a different filename
    files = %w[ss_ontap.txt ss.txt]
    if block_given?
      files.each { |f| yield f }
    else
      files
    end
  end
end
