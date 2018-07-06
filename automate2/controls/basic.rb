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
    desc "
    Internal #{service.name} service is not running or has a short runtime, check the logs
    and make sure the service is not flapping.
    "

    describe service do
      its('status') { should eq 'running' }
      its('runtime') { should cmp >= 80 }
    end
  end
end
#
# services.external do |service|
#   control "gatherlogs.automate.external_service_status.#{service.name}" do
#     title "check that external #{service.name} is running"
#     desc "
#       External #{service.name} service is not running or has a short runtime, check the logs
#       and make sure the service is not flapping.
#     "
#
#     describe service do
#       its('status') { should eq 'run' }
#       its('connection_status') { should eq 'OK' }
#     end
#   end
# end

df = disk_usage()

%w(/ /hab /var/log).each do |mount|
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
