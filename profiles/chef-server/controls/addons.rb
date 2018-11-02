reporting = installed_packages('opscode-reporting')
manage = installed_packages('chef-manage')
manage = installed_packages('opscode-manage') unless manage.exists?
sync = installed_packages('chef-sync')

control '030.gatherlogs.chef-server.reporting-with-2018-partition-tables' do
  title 'make sure installed reporting version has 2018 parititon tables fix'
  desc "
  Reporting < 1.7.10 has a bug where it does not create the 2018
  partition tables. In order to fix this the user should install reporting >= 1.8.0

  Version: #{reporting.version}
"

  tag kb: 'https://getchef.zendesk.com/hc/en-us/articles/360001425252-Fixing-missing-2018-Reporting-partition-tables'

  sysinfo = {
    'Reporting' => reporting.exists? ? reporting.version : 'Not Installed',
    'Manage' => manage.exists? ? manage.version : 'Not Installed'
  }
  sysinfo['Sync'] = sync.version if sync.exists?

  tag system: sysinfo

  only_if { reporting.exists? }

  describe reporting do
    its('version') { should cmp >= '1.7.10' }
  end
end
