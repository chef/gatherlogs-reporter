title 'Basic checks for Automate 1 configuration'

include_controls 'common'

automate = installed_packages('automate')

control '000.gatherlogs.automate.package' do
  impact 'medium'
  title 'Check that Automate 1 is installed and at a recent version'
  desc "
  Automate 1 was not found, or is running an older version. Please upgrade
  to a newer version of Automate 1: https://downloads.chef.io/automate
  "

  tag system: { "Product": "Automate #{automate.version}" }

  describe automate do
    it { should exist }
    its('version') { should cmp >= '1.8.38' }
  end
end

control 'gatherlogs.automate.required_memory' do
  impact 'medium'
  title 'Check that the system has the required amount of memory'
  desc "
  Chef recommends that an Automate 1 system has at least 16GB of memory.
  Please make sure the system meets the minimum hardware requirements.
  "

  tag verbose: true
  tag system: {
    'Total Memory' => "#{memory.total_mem} MB",
    'Free Memory' => "#{memory.free_mem} MB",
    'Total Swap' => "#{memory.total_swap} MB",
    'Free Swap' => "#{memory.free_swap} MB"
  }

  describe memory do
    # rough calculation for 15GB because reasons
    its('total_mem') { should cmp >= 15_360 }
    its('free_swap') { should cmp > 0 }
  end
end

services = service_status(:automate)

control 'gatherlogs.automate.internal_service_status' do
  impact 'high'
  title 'Check that Automate 1 internal services are running'
  desc "
  One or more Automate 1 internal services are not running or have a short runtime.
  Check the logs to make sure that services are not flapping.
  "

  tag verbose: true

  describe services do
    it { should exist }
  end

  services.internal do |service|
    describe service do
      its('status') { should eq 'run' }
      its('runtime') { should cmp >= 80 }
    end
  end
end

services.external do |service|
  control "gatherlogs.automate.external_service_status.#{service.name}" do
    impact 'high'
    title "Check that Automate 1 external service #{service.name} is running"
    desc "
    The Automate 1 external service #{service.name} is not running or has a short runtime.
    Check the logs to make sure that the service is not flapping.
    "

    describe service do
      its('status') { should eq 'run' }
      its('connection_status') { should eq 'OK' }
    end
  end
end

df = disk_usage

%w[/ /var /var/opt /var/opt/delivery /var/log].each do |mount|
  control "gatherlogs.automate.critical_disk_usage.#{mount}" do
    impact 'critical'
    title 'check that the automate has plenty of free space'
    desc "
    There are several key directories that we need to make sure have enough
    free space for Automate 1 to operate normally.
    "

    tag verbose: true
    only_if { df.exists?(mount) }

    describe df.mount(mount) do
      its('used_percent') { should cmp < 100 }
      its('available') { should cmp > disk_usage.to_filesize('250M') }
    end
  end
end

control 'gatherlogs.automate.sysctl-settings' do
  impact 'medium'
  title 'Check that the sysctl settings make sense'
  desc "
  Recommended sysctl settings are not correct. These should be updated
  to ensure a performant Automate 1 system.
  "

  tag verbose: true
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
