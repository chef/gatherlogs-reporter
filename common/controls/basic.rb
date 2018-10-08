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
Entries for 'Out of memory: Kill process' where found in 'dmesg.txt'

Please make sure that the system has enough RAM available to handle the
client load on the system.

#{dmesg_oom.summary}

For Automate review: https://pages.chef.io/rs/255-VFB-268/images/ScalingChefAutomate_2017.pdf"
  only_if { dmesg_oom.log_exists? }

  describe dmesg_oom do
    its('last_entry') { should be_empty }
  end
end

dmesg_contrack = log_analysis('dmesg.txt', 'nf_conntrack: table full, dropping packet')

control "gatherlogs.common.dmesg-nf_conntrack-table-full-error" do
  title "Check to see if the kernel is reporting the nf_conntrack table is full"
  desc "
  #{dmesg_contrack.hits} entries for 'nf_conntrack: table full, dropping packet.' where found in 'dmesg.txt'

  One possible cause of this can happen when there is a large number of push-job
  clients checking into the node all at once.

  Check the current value using: `sysctl net.netfilter.nf_conntrack_max`
  Update setting using: `sysctl -w sysctl -w net.netfilter.nf_conntrack_max=131072`
  "

  only_if { dmesg_contrack.log_exists? }

  describe dmesg_contrack do

    its('last_entry') { should be_empty }
  end
end
