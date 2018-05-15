# encoding: utf-8
# copyright: 2018, The Authors

title 'GatherLog inspec profile to check for common problems with Chef Automate'

# you add controls here
control 'automate.gatherlogs.missing-data-collector-token' do
  impact 0.5
  title 'Check to see if there are errors about missing data collector tokens'
  desc '
  If nodes are not showing up in the Automate UI we should check to make sure
  that there are no complaints about missing data collector tokens
  '

  %w{ console.log current }.each do |logfile|
    describe file(::File.join('var/log/delivery/delivery', logfile)) do                  # The actual test
      its('content') { should_not match(/Data Collector request made without access token/) }
    end
  end
end

control 'automate.gatherlogs.rogue-notificatinos-process' do
  impact 0.5
  title 'Check to see if there is a rogue notifications process'
  desc "
  On occasion the notifications.sh process will not restart properly or get
  orphaned and will be owned by PID 1.  Once this happens it's not possible to
  restart it using `automate-ctl restart notifications` and requires killing
  the process by hand.
  "

  
end
