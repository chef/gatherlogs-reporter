control 'gatherlogs.chef-server.check_for_drbd' do
  impact 0.5
  title 'Check to see if the system is using legacy DRDB HA configuration'
  desc '
It appears that the chef-server has a legacy DRBD configuration.
This feature will be end-of-life for support on March 31, 2019.
'

  tag kb: 'https://blog.chef.io/2018/10/02/end-of-life-announcement-for-drbd-based-ha-support-in-chef-server/'

  describe file('private-chef-ctl_ha-status.txt') do
    it { should_not exist }
  end
end
