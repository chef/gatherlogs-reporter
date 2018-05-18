title 'Basic checks for the automate configuration'

include_controls 'common'

control "gatherlogs.automate.platform" do
  title "check platform is valid"
  desc "make sure the platform does not contain an unknown value"
  impact 1.0

  describe platform_version do
    its('content') { should_not match(/Platform and version are unknown/) }
  end
end

automate = installed_packages('automate')

control "gatherlogs.automate.package" do
  title "check that automate is installed"
  desc "make sure the chef-server package shows up in the installed packages"

  impact 1.0

  describe automate do
    it { should exist }
    its('version') { should cmp >= '1.8.38'}
  end
end


services = service_status(:automate)

services.each do |service|
  control "gatherlogs.automate.service_status.#{service.name}" do
    title "check that #{service.name} is running"
    desc "make sure that the #{service.name} is reporting as running"

    describe service do
      its('status') { should eq 'run' }
      its('runtime') { should cmp >= 60 }
    end
  end
end

df = disk_usage()

%w(/ /var /var/opt /var/opt/delivery /var/log).each do |mount|
  control "gatherlogs.automate.critical_disk_usage.#{mount}" do
    title "check that the automate has plenty of free space"
    desc "
      there are several key directories that we need to make sure have enough
      free space for automate to operate succesfully
    "

    only_if { df.exists?(mount) }

    describe df.mount(mount) do
      its('used_percent') { should cmp < 100 }
      its('available') { should cmp > 1 }
    end
  end
end
