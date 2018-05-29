title "Checks for common gatherlog files"

control "gatherlogs.common.platform" do
  title "check platform is valid"
  desc "
    Gather-logs was run on an unknown platform. This usually happens when
    running on Amazon Linux
  "
  impact 1.0

  describe platform_version do
    its('content') { should_not match(/Platform and version are unknown/) }
  end
end

control "gatherlogs.common.umask" do
  title "check that we have a reasonable umask setting"
  desc "
    If the umask is not set to 0022 it can lead to issues with files not being
    accessible to the services
  "
  only_if { file('umask.txt').exist? }

  describe file('umask.txt') do
    its('content') { should match /0022/ }
  end
end

dmesg_oom = log_analysis('dmesg.txt', 'Out of memory: Kill process')

control "gatherlogs.common.dmesg-oom-killer-invoked" do
  title "Check to see if the kernel OOM kill was invoked"
  desc "
  #{dmesg_oom.hits} entries for 'Out of memory: Kill process' where found in 'dmesg.txt'

  Please make sure that the system has enough RAM available to it handle the
  client load on the system.
  "

  describe dmesg_oom do
    it { should_not exist }
  end
end
