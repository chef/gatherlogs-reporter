drbd = file('private-chef-ctl_ha-status.txt')
topology = log_analysis('etc/opscode/chef-server.rb', 'topology')
fe_node = log_analysis('etc/opscode/chef-server.rb', 'use_chef_backend true')

system_info = { 'DRBD Enabled' => drbd.exist? ? 'Yes' : 'No' }
system_info['HA Front-End'] = 'Yes' if fe_node.exists?
system_info['Topology'] = topology.last.split(/\s+/).last if topology.exists?

control '041.gatherlogs.chef-server.check_for_drbd' do
  impact 0.5
  title 'Check to see if the system is using legacy DRDB HA configuration'
  desc '
Chef-server is using a legacy DRBD HA configuration.
This feature will reach end-of-life for support on March 31, 2019.
'
  tag kb: 'https://blog.chef.io/2018/10/02/end-of-life-announcement-for-drbd-based-ha-support-in-chef-server/'
  tag system: system_info

  describe drbd do
    it { should_not exist }
  end
end
