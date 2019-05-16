title 'Checks for common gatherlog files'

control '020.gatherlogs.common.system_info' do
  sysinfo = {}

  if file('uptime.txt').exist?
    sysinfo['Uptime'] = file('uptime.txt').content.lines.last.chomp
  end

  if cpu_info.exists?
    sysinfo['CPU Cores'] = cpu_info.total
    sysinfo['CPU Model'] = cpu_info.model_name
  end

  tag system: sysinfo
end

control '020.gatherlogs.common.platform' do
  title 'check platform is valid'
  desc "
    Gather-logs was run on an unknown platform. This usually happens when
    running on Amazon Linux
  "

  tag system: { 'Platform' => platform_version.full_info } if platform_version.exists?
  tag verbose: true

  only_if { platform_version.exists? }

  describe platform_version do
    its('content') { should_not match(/Platform and version are unknown/) }
  end
end

control 'gatherlogs.common.umask' do
  title 'check that we have a reasonable umask setting'
  desc "
    If the umask is not set to 0022 it can lead to issues with files not being
    accessible to the services
  "
  only_if { file('umask.txt').exist? }
  tag verbose: true

  describe file('umask.txt') do
    its('content') { should match(/0022/) }
  end
end

dmesg_oom = log_analysis('dmesg.txt', 'Out of memory: Kill process')

control 'gatherlogs.common.dmesg-oom-killer-invoked' do
  title 'Check to see if the kernel OOM kill was invoked'
  desc "
Entries for 'Out of memory: Kill process' where found in 'dmesg.txt'

Please make sure that the system has enough RAM available to handle the
client load on the system.

For Automate v1: https://pages.chef.io/rs/255-VFB-268/images/ScalingChefAutomate_2017.pdf
For Automate v2: https://www.chef.io/wp-content/uploads/2018/05/Scaling_Chef_Automate_Beyond_100000_Nodes.pdf
"

  tag summary: dmesg_oom.summary

  only_if { dmesg_oom.log_exists? }

  describe dmesg_oom do
    its('last_entry') { should be_empty }
  end
end

dmesg_contrack = log_analysis('dmesg.txt', 'nf_conntrack: table full, dropping packet')

control 'gatherlogs.common.dmesg-nf_conntrack-table-full-error' do
  title 'Check to see if the kernel is reporting the nf_conntrack table is full'
  desc "
  The nf_conntrack table is full and is causing the kernel to drop packets.

  If you are using the push-jobs server this can happen if a large number push-clients checking all at once.
  A workaround for this is to adjust the value for `net.netfliter.nf_conntrac_max` in sysctl

  To get the current value: `sysctl net.netfilter.nf_conntrack_max`
  To update the value: `sysctl -w net.netfilter.nf_conntrack_max=131072`
  "

  tag summary: dmesg_contrack.summary

  only_if { dmesg_contrack.log_exists? }

  describe dmesg_contrack do
    its('last_entry') { should be_empty }
  end
end

xfs_errors = log_analysis('dmesg.txt', 'XFS .* error .* returned', case_sensitive: true)
xfs_shutdown = log_analysis('dmesg.txt', 'xfs_do_force_shutdown')

control 'gatherlogs.common.xfs_disk_error' do
  title 'Check to see if XFS is reporting any disk errors'
  desc "
XFS is reporting errors, this likely means that a filesystem has
encountered a runtime error and has shut down.  Check the rest of the dmesg or
kernel logs to see what might have lead to this event.
  "

  tag summary: [xfs_errors.summary, xfs_shutdown.summary]

  describe xfs_errors do
    its('last_entry') { should be_empty }
  end

  describe xfs_shutdown do
    its('last_entry') { should be_empty }
  end
end

common_logs.ss_ontap do |ss_ontap|
  port_exhaustion = log_analysis(ss_ontap, 'TIME-WAIT|ESTAB')
  control "gatherlogs.common.port_exhaustion.#{ss_ontap}" do
    title 'Check to see if all the available ports have been used'
    desc "
  There appears to be a large number of open ports on the system.  This
  can cause high cpu and memory usage on the system as services queue requests
  waiting for a port to become available for message processing.

  This can sometimes happen if a service like ElasticSearch is unable to process
  requests fast enough. Try restarting the Chef-Server/Automate services and
  monitor the system to see if it starts to happen again. If so ensure there
  are no performance issues with the system due to high I/O wait times or
  other services using a large amount of memory.
    "

    tag verbose: true
    describe port_exhaustion do
      its('count') { should be < 10000 }
    end
  end
end
