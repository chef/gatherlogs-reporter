title 'Basic checks for the chef-server configuration'

chef_server = installed_packages('chef-server-core')

control "chef-server.gatherlogs.chef-server" do
  title "check that chef-server is installed"
  desc "make sure the chef-server package shows up in the installed packages"

  impact 1.0

  describe chef_server do
    it { should exist }
    its('version') { should cmp >= '12.17.0'}
  end
end

df = disk_usage()

%w(/ /var /var/opt /var/opt/opscode /var/log).each do |mount|
  control "chef-server.gatherlogs.critical_disk_usage.#{mount}" do
    title "check that the chef-server has plenty of free space"
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

control "chef-server.gatherlogs.platform" do
  title "check platform is valid"
  desc "make sure the platform does not contain an unknown value"
  impact 1.0

  describe platform_version do
    its('content') { should_not match(/Platform and version are unknown/) }
  end
end
