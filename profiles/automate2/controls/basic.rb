title 'Basic checks for the automate2 configuration'

include_controls 'common'

automate = installed_packages('automate2')

control '000.gatherlogs.automate2.package' do
  title 'check that Automate 2 is installed'
  desc "
  Automate was not found or is running an older version, please upgraded
  to a newer version of Automate 2
  "

  tag system: { "Product": "Automate v2 #{automate.version}" }
  describe automate do
    it { should exist }
  end
end

control '000.gatherlogs.automate2.system_info' do
  tag system: {
    'Habitat' => file('hab_version.txt').content.lines.last.chomp
  }
end

services = service_status(:automate2)

control '000.gatherlogs.automate2.internal_service_status' do
  title 'check that Automate services are running'
  desc "
One or more Automate services are reporting issues. Please check for any
services that might be failed, have a short run time or failing their health
checks.
"

  impact 'critical'

  tag verbose: true

  describe services do
    it { should exist }
  end

  services.internal do |service|
    describe service do
      its('status') { should eq 'running' }
      its('health') { should eq 'ok' }
      its('runtime') { should cmp >= 90 }
    end
  end
end

df = disk_usage

control 'gatherlogs.automate2.critical_disk_usage' do
  title 'check that the automate has plenty of free space'
  desc "
    There are several key directories that we need to make sure have enough
    free space for automate to operate succesfully
  "

  impact 'critical'
  tag verbose: true

  %w[/ /hab /var /var/log].each do |mount|
    next unless df.exists?(mount)

    describe df.mount(mount) do
      its('used_percent') { should cmp < 100 }
      its('available') { should cmp > disk_usage.to_filesize('250M') }
    end
  end
end

control 'gatherlogs.automate2.required_memory' do
  title 'Check that the system has the required amount of memory'

  desc "
Chef recommends that the Automate2 system has at least 16GB of memory.
Please make sure the system means the minimum hardware requirements
"

  tag kb: 'https://automate.chef.io/docs/system-requirements/'
  tag verbose: true
  tag system: {
    'Total Memory' => "#{memory.total_mem} MB",
    'Free Memory' => "#{memory.free_mem} MB"
  }

  describe memory do
    # rough calculation for 15gb because of reasons
    its('total_mem') { should cmp >= 15_360 }
    its('free_swap') { should cmp > 0 }
  end
end

control 'gatherlogs.automate2.sysctl-settings' do
  title 'check that the sysctl settings make sense'
  desc "
    Recommended sysctl settings are not correct, recommend that these get updated
    to ensure the best performance possible for Automate 2.
  "
  only_if { sysctl.exists? }
  describe sysctl do
    its('vm_swappiness') { should cmp >= 1 }
    its('vm_swappiness') { should cmp <= 20 }
    its('fs_file-max') { should cmp >= 64_000 }
    its('vm_max_map_count') { should cmp >= 256_000 }
    its('vm_dirty_ratio') { should cmp >= 5 }
    its('vm_dirty_ratio') { should cmp <= 30 }
    its('vm_dirty_background_ratio') { should cmp >= 10 }
    its('vm_dirty_background_ratio') { should cmp <= 60 }
    its('vm_dirty_expire_centisecs') { should cmp >= 10_000 }
    its('vm_dirty_expire_centisecs') { should cmp <= 30_000 }
  end
end

failed_preflight_checks = log_analysis('chef-automate_preflight-check.txt', 'FAIL', case_sensitive: true)
control 'gatherlogs.automate2.failed_preflight_checks' do
  title 'Check automate preflight output for any failed tests'
  desc "
Automate preflight checks are reporting issues failures, the failure for 'automate already deployed'
is expected but other failures are being reported.

If sysctl settings are being reported as failed be sure to update your 'syctl.conf'
with the required settings to ensure they persist through system reboots

Please check the chef-automate_preflight-check.txt for ways to remediate the failed tests.
  "
  tag summary: failed_preflight_checks.messages

  describe failed_preflight_checks do
    its('hits') { should cmp <= 1 }
  end
end

notification_error = log_analysis('journalctl_chef-automate.txt', 'Notifications.WebhookSender.Impl \[error\] .* failed to post', a2service: 'notifications-service.default')
control 'gatherlogs.automate2.notifications-failed-to-send' do
  title 'Check to see if the notifications services is reporting errors sending messages'
  desc 'The notification service is encountering an error when trying to set a message to the webhook endpoint'

  tag summary: notification_error.summary

  describe notification_error do
    its('last_entry') { should be_empty }
  end
end

control 'gatherlogs.automate2.required_cpu_cores' do
  title 'Check that the system has the required number of cpu cores'

  desc "
Chef recommends that the Automate v2 systems have at least 4 cpu cores.
Please make sure the system means the minimum hardware requirements
"

  tag kb: 'https://automate.chef.io/docs/system-requirements/#hardware'
  tag verbose: true

  describe cpu_info do
    its('total') { should cmp >= 4 }
  end
end
