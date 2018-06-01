# encoding: utf-8
# copyright: 2018, The Authors

title 'GatherLog inspec profile to check for common problems with Chef Automate'

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

  %w{ console.log current }.each do |logfile|
    data_collector = log_analysis(::File.join('var/log/delivery/delivery', logfile), 'Data Collector request made without access token')
    describe data_collector do                  # The actual test
      it { should_not exist }
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
    it { should_not exist }
  end
end
