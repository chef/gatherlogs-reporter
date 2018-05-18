title 'Basic checks for the chef-server configuration'

include_controls 'common'

chef_server = installed_packages('chef-server-core')

control "gatherlogs.chef-server.package" do
  title "check that chef-server is installed"
  desc "make sure the chef-server package shows up in the installed packages"

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
    This is a quick check to see if the user is running an older version
    of chef-server that uses postgresql 9.2.  If so a major upgrade to
    postgresql 9.6 will be required as part of the upgrade.
  "

  impact 0.5

  only_if { chef_server.exists? }
  describe chef_server do
    its('version') { should cmp >= '12.16.2' }
  end
end

services = service_status(:chef_server)

services.each do |service|
  control "gatherlogs.chef-server.service_status.#{service.name}" do
    title "check that #{service.name} is running"
    desc "make sure that the #{service.name} is reporting as running"

    describe service do
      its('status') { should eq 'run' }
      its('runtime') { should cmp >= 60 }
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
