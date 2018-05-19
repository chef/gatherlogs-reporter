title 'Basic checks for the chef-server configuration'

include_controls 'common'

chef_server = installed_packages('chef-server-core')

control "gatherlogs.chef-server.package" do
  title "check that chef-server is installed"
  desc "The installed version of Chef-Server is old and should be upgraded"

  impact 1.0

  only_if { chef_server.exists? }
  describe chef_server do
    it { should exist }
    its('version') { should cmp >= '12.17.0'}
  end
end

control "gatherlogs.chef-server.postgreql-upgrade-applied" do
  title "make sure customer is using chef-server version that includes postgresl 9.6"
  desc "
    Chef Server < 12.16.2 uses PostgreSQL 9.2 and will perform a major upgrade
    to 9.6.  Please make sure there is enough disk space available to perform
    the upgrade as it will duplicate the database on disk.
  "

  impact 0.5

  only_if { chef_server.exists? }
  describe chef_server do
    its('version') { should cmp >= '12.16.2' }
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
      its('runtime') { should cmp >= 60 }
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

df = disk_usage()

%w(/ /var /var/opt /var/opt/opscode /var/log).each do |mount|
  control "gatherlogs.chef-server.critical_disk_usage.#{mount}" do
    title "check that #{mount} has plenty of free space"
    desc "
      there are several key directories that we need to make sure have enough
      free space for chef-server to operate succesfully
    "

    only_if { df.exists?(mount) }

    describe df.mount(mount) do
      its('used_percent') { should cmp < 100 }
      its('available') { should cmp > 1 }
    end
  end
end
