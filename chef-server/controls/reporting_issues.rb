reporting = installed_packages('opscode-reporting')

control "chef-server.gatherlogs.reporting-with-2018-partition-tables" do
  title "make sure installed reporting version has 2018 parititon tables fix"
  desc "
    Reporting < 1.7.10 has a bug where it does not create the 2018
    partition tables. In order to fix this the user should install >= 1.8.0
    and follow the instructions in this KB:
    https://getchef.zendesk.com/hc/en-us/articles/360001425252-Fixing-missing-2018-Reporting-partition-tables
  "

  impact 1.0

  only_if { reporting.exists? }

  describe reporting do
    its('version') { should cmp >= '1.7.10'}
  end
end
