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
    describe file(::File.join('var/log/delivery/delivery', logfile)) do                  # The actual test
      its('content') { should_not match(/Data Collector request made without access token/) }
    end
  end
end
