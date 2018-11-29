title 'Basic checks for the chef-server configuration'

include_controls 'common'

chef_server = installed_packages('chef-server-core')

control '000.gatherlogs.chef-server.package' do
  title 'check that chef-server is installed'
  desc "
  The installed version of Chef-Server is old and should be upgraded
  Installed version: #{chef_server.version}
  "

  tag system: {
    'Product' => "Chef-Server #{chef_server.version}"
  }

  only_if { chef_server.exists? }
  describe chef_server do
    it { should exist }
    its('version') { should cmp >= '12.17.0' }
  end
end

control 'gatherlogs.chef-server.postgreql-upgrade-applied' do
  title 'make sure customer is using chef-server version that includes postgresl 9.6'
  desc "
    Chef Server < 12.16.2 uses PostgreSQL 9.2.

    Upgrading to a newer version of Chef Server requires a major upgrade to
    9.6, make sure there is enough free disk space create a copy during the
    upgrade process.
  "

  impact 0.5

  only_if { chef_server.exists? }
  describe chef_server do
    its('version') { should cmp >= '12.16.2' }
  end
end

license = log_analysis('etc/opscode/chef-server.rb', 'license')
ldap = log_analysis('etc/opscode/chef-server.rb', "ldap\\\[['\"'\"'\"]host['\"'\"'\"]\\\]")
sys_info = {
  'LDAP Enabled' => ldap.exists? ? 'Yes' : 'No'
}
sys_info['License count'] = license.last.split('=').last unless license.last.nil?

control '040.gatherlogs.chef-server.system_info' do
  title 'Include any configuration information for chef-server'

  tag system: sys_info
  only_if { license.exists? }
end

control '010.gatherlogs.chef-server.required_memory' do
  title 'Check that the system has the required amount of memory'

  desc "
Chef recommends that the Chef-Server system has at least 8GB of memory.
Please make sure the system means the minimum hardware requirements
"

  tag kb: 'https://docs.chef.io/chef_system_requirements.html#chef-server-on-premises-or-in-cloud-environment'
  tag verbose: true
  tag system: {
    'Total Memory' => "#{memory.total_mem} MB",
    'Free Memory' => "#{memory.free_mem} MB"
  }

  describe memory do
    # rough calculation for 8gb because of reasons
    its('total_mem') { should cmp >= 7168 }
    its('free_swap') { should cmp > 0 }
  end
end

control '010.gatherlogs.chef-server.required_cpu_cores' do
  title 'Check that the system has the required number of cpu cores'

  desc "
Chef recommends that the Chef-Server and Frontend systems have at least 4 cpu cores.
Please make sure the system means the minimum hardware requirements
"

  tag kb: 'https://docs.chef.io/chef_system_requirements.html#chef-server-on-premises-or-in-cloud-environment'
  tag verbose: true
  if cpu_info.exists?
    tag system: {
      'CPU Cores' => cpu_info.total,
      'CPU Model' => cpu_info.model_name
    }
  end

  describe cpu_info do
    # rough calculation for 8gb because of reasons
    its('total') { should cmp >= 4 }
  end
end

services = service_status(:chef_server)

services.internal do |service|
  control "gatherlogs.chef-server.internal_service_status.#{service.name}" do
    title "check that internal #{service.name} is running"
    desc "
      Internal #{service.name} service is not running or has a short runtime, check the logs
      and make sure the service is not flapping.
    "

    describe service do
      its('status') { should eq 'run' }
      its('runtime') { should cmp >= 80 }
    end
  end
end

services.external do |service|
  control "gatherlogs.chef-server.external_service_status.#{service.name}" do
    title "check that external #{service.name} is running"
    desc "
      External #{service.name} service is not running or has a short runtime,
      check the logs and make sure the service is not flapping.
    "

    describe service do
      its('status') { should eq 'run' }
      its('connection_status') { should eq 'OK' }
    end
  end
end

df = disk_usage

%w[/ /var /var/opt /var/opt/opscode /var/log].each do |mount|
  control "gatherlogs.chef-server.critical_disk_usage.#{mount}" do
    title "check that #{mount} has plenty of free space"
    desc "
      there are several key directories that we need to make sure have enough
      free space for chef-server to operate succesfully
    "

    only_if { df.exists?(mount) }

    describe df.mount(mount) do
      its('used_percent') { should cmp < 100 }
      its('available') { should cmp > disk_usage.to_filesize('250M') }
    end
  end
end
