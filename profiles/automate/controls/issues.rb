# copyright: 2018, The Authors

title 'GatherLog Chef InSpec profile to check for common problems with Chef Automate'

# you add controls here
control 'gatherlogs.automate.missing-data-collector-token' do
  impact 0.5
  title 'Check to see if there are errors about missing data collector tokens'
  desc '
  Automate is complaining about missing data collector tokens, some nodes may
  not be visible in Automate.

  Check to make sure that the Chef-Server or client.rb files have the correct
  data collector token configured. See: https://docs.chef.io/data_collection.html
  '

  %w[console.log current].each do |logfile|
    data_collector = log_analysis(::File.join('var/log/delivery/delivery', logfile), 'Data Collector request made without access token')
    describe data_collector do # The actual test
      its('last_entry') { should be_empty }
    end
  end
end

logstash = log_analysis('var/log/delivery/logstash*/current', 'java.lang.OutOfMemoryError: Java heap space')

control 'gatherlogs.automate.logstash-out-of-memory' do
  impact 1
  title 'Check to see if logstash is running out of heap space'
  desc "
  Found #{logstash.hits} messages about 'java.lang.OutOfMemoryError: Java heap space'
  in 'var/log/delivery/logstash*/current'

  When logstash runs out of heap space the process will get killed and restarted
  this will cause a delay in the processing of the queue and can cause it to
  expand.
  "

  describe logstash do
    its('last_entry') { should be_empty }
  end
end

automate = installed_packages('automate')

control 'gatherlogs.automate.broken-reaper-cron-file-1.8.3' do
  title 'Check for version of Automate with broken reaper cron file'
  desc "
  It appears you are running Automate 1.8.3, which creates a broken reaper cron
  file in `/etc/cron.d/reaper`. Cron requires that the file contains a blank line
  before the end of the file and will fail to run if it's not included.

  Please upgrade to a newer version of Automate to ensure reaper run correctly.
  "

  describe automate do
    its('version') { should_not cmp == '1.8.3' }
  end
end

es_disk = log_analysis('var/log/delivery/elasticsearch/current', 'high disk watermark exceeded on one or more nodes')

control 'gatherlogs.automate.elasticsearch-disk-space-errors' do
  impact 1
  title 'Check to see if ElasticSearch is erroring because of available disk space'
  desc "
When ElasticSearch detects that there is not enough free space on the disk it will
stop accepting new documents to prevent corrupting the database.  You will need
to free up disk space to fix this issue.

Make sure that the Automate Reaper is enable and working, to configure the data
retention policy in Automate please review:
https://docs.chef.io/data_retention_chef_automate.html
  "

  tag summary: es_disk.summary

  describe es_disk do
    its('last_entry') { should be_empty }
  end
end

# Cannot allocate 762886488 bytes of memory
rabbit_mem = log_analysis('var/log/delivery/rabbitmq/current', 'Cannot allocate \d+ bytes of memory')

control 'gatherlogs.automate.rabbitmq-memory-allocation-error' do
  impact 1
  title 'Check to see if RabbitMQ is erroring because of memory allocation errors'
  desc "
RabbitMQ is unable to allocate enough memory to operate correctly. Please check
that there is enough RAM available on the system
  "
  tag summary: rabbit_mem.summary

  describe rabbit_mem do
    its('last_entry') { should be_empty }
  end
end

notifications = log_analysis('var/log/delivery/notifications/current', 'application_start_failure.*eacces')
control 'gatherlogs.automate.notifications-start-failure' do
  title 'Check to see if the notifications service is failing to start'
  desc '
Notification service is encountering an error accessing a file and is unable to
start, check the error message for the specific file.
'

  tag summary: notifications.summary

  describe notifications do
    its('last_entry') { should be_empty }
  end
end
