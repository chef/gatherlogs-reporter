title 'Basic checks for the automate configuration'

automate = installed_packages('automate')

control "chef-server.gatherlogs.automate" do
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
  control "chef-server.gatherlogs.service_status.#{service.name}" do
    title "check that #{service.name} is running"
    desc "make sure that the #{service.name} is reporting as running"

    describe service do
      its('status') { should eq 'run' }
      its('runtime') { should cmp >= 60 }
    end
  end
end
