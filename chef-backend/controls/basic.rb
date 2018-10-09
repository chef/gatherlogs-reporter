title 'Basic checks for the chef-server configuration'

include_controls 'common'

chef_backend = installed_packages('chef-backend')

control "gatherlogs.chef-backend.package" do
  title "check that chef-backend is installed"
  desc "
  The installed version of Chef-Backend is old and should be upgraded
  Installed version: #{chef_backend.version}
  "

  only_if { chef_backend.exists? }
  describe chef_backend do
    it { should exist }
    its('version') { should cmp >= '2.0.30'}
  end
end

df = disk_usage()

%w(/ /var /var/opt /var/opt/chef-backend /var/log).each do |mount|
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

services = service_status(:chef_backend)

services.internal do |service|
  control "gatherlogs.chef-backend.service_status.#{service.name}" do
    title "check that #{service.name} service is running"
    desc "There was a problem with the #{service.name} service.  Please check that it's
running, doesn't have a short run time, or the health checks are reporting an issue.

#{service.summary}"

    describe service do
      its('status') { should eq 'running' }
      its('runtime') { should cmp >= 90 }
    end
  end
end
