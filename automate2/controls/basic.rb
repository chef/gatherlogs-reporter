title 'Basic checks for the automate2 configuration'

include_controls 'common'

# automate = installed_packages('automate2')
#
# control "gatherlogs.automate2.package" do
#   title "check that Automate 2 is installed"
#   desc "
#   Automate was not found or is running an older version, please upgraded
#   to a newer version of Automate 2
#   "
#
#   impact 1.0
#
#   describe automate do
#     it { should exist }
#     its('version') { should cmp >= '0'}
#   end
# end


services = service_status(:automate2)

services.internal do |service|
  control "gatherlogs.automate2.internal_service_status.#{service.name}" do
    title "check that #{service.name} service is running"
    desc "There was a problem with the #{service.name} service.  Please check that it's
running, doesn't have a short run time, or the health checks are reporting an issue."

    tag summary: service.summary

    describe service do
      its('status') { should eq 'running' }
      its('health') { should eq 'ok' }
      its('runtime') { should cmp >= 90 }
    end
  end
end

df = disk_usage()

%w(/ /hab /var /var/log).each do |mount|
  control "gatherlogs.automate2.critical_disk_usage.#{mount}" do
    title "check that the automate has plenty of free space"
    desc "
      There are several key directories that we need to make sure have enough
      free space for automate to operate succesfully
    "

    only_if { df.exists?(mount) }

    describe df.mount(mount) do
      its('used_percent') { should cmp < 100 }
      its('available') { should cmp > disk_usage.to_filesize('250M') }
    end
  end
end

control "gatherlogs.automate2.sysctl-settings" do
  title "check that the sysctl settings make sense"
  desc "
    Recommended sysctl settings are not correct, recommend that these get updated
    to ensure the best performance possible for Automate 2.
  "
  only_if { sysctl_a.exists? }
  describe sysctl_a do
    its('vm_swappiness') { should cmp >= 1 }
    its('vm_swappiness') { should cmp <= 20 }
    its('fs_file-max') { should cmp >= 64000 }
    its('vm_max_map_count') { should cmp >= 256000 }
    its('vm_dirty_ratio') { should cmp >= 5 }
    its('vm_dirty_ratio') { should cmp <= 30 }
    its('vm_dirty_background_ratio') { should cmp >= 10 }
    its('vm_dirty_background_ratio') { should cmp <= 60 }
    its('vm_dirty_expire_centisecs') { should cmp >= 10000 }
    its('vm_dirty_expire_centisecs') { should cmp <= 30000 }
  end
end

failed_preflight_checks = log_analysis("chef-automate_preflight-check.txt", 'FAIL')
control "gatherlogs.automate2.failed_preflight_checks" do
  impact 1.0
  title 'Check automate preflight output for any failed tests'
  desc "
Automate preflight checks are reporting issues failures, the failure for 'automate already deployed'
is expected but other failures are being reported.

If sysctl settings are being reported as failed be sure to update your 'syctl.conf'
with the required settings to ensure they persist through system reboots

Please check the chef-automate_preflight-check.txt for ways to remediate the failed tests.

Failed checks:
#{failed_preflight_checks.messages.join("\n")}
  "

  describe failed_preflight_checks do
    its('hits') { should cmp == 1 }
  end
end


notification_error = log_analysis("journalctl_chef-automate.txt", 'Notifications.WebhookSender.Impl \[error\] .* failed to post', a2service: 'notifications-service.default')
control "gatherlogs.automate2.notifications-failed-to-send" do
  impact 1.0
  title 'Check to see if the notifications services is reporting errors sending messages'
  desc "
  The notification service is encountering an error when trying to set a message to the
  webhook endpoint

  #{notification_error.hits} total errors found

  Last matching log entry:
  #{notification_error.last_entry}
  "

  describe notification_error do
    its('last_entry') { should be_empty }
  end
end
