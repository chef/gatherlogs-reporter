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
