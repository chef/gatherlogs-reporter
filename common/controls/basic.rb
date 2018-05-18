title "Checks for common gatherlog files"

control "gatherlogs.common.platform" do
  title "check platform is valid"
  desc "make sure the platform does not contain an unknown value"
  impact 1.0

  describe platform_version do
    its('content') { should_not match(/Platform and version are unknown/) }
  end
end

control "gatherlogs.common.umask" do
  title "check that we have a reasonable umask setting"
  desc "
    if this is not set correctly it can lead to issues with files not being
    accessible to the services
  "
  only_if { file('umask.txt').exist? }

  describe file('umask.txt') do
    its('content') { should match /0022/ }
  end
end


control "gatherlogs.common.sysctl-settings" do
  title "check that the sysctl settings make sense"
  desc "
    there are several recommended settings for sysctl check to make sure the
    current active ones make sense
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
    its('vm_dirty_expire_centisecs') { should cmp >= 30000 }
  end
end
