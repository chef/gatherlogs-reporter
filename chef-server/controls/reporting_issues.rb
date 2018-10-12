reporting = installed_packages('opscode-reporting')

control "gatherlogs.chef-server.reporting-with-2018-partition-tables" do
  title "make sure installed reporting version has 2018 parititon tables fix"
  desc '
  Reporting < 1.7.10 has a bug where it does not create the 2018
  partition tables. In order to fix this the user should install reporting >= 1.8.0
  '

  tag kb: 'https://getchef.zendesk.com/hc/en-us/articles/360001425252-Fixing-missing-2018-Reporting-partition-tables'

  only_if { reporting.exists? }

  describe reporting do
    its('version') { should cmp >= '1.7.10'}
  end
end
