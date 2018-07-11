#level=error msg="Phase failed" error="hab-sup upgrade pending" phase="supervisor upgrade"

upgrade_failed = log_analysis("journalctl_chef-automate.txt", 'level=error msg="Phase failed" error="hab-sup upgrade pending" phase="supervisor upgrade"', a2service: 'service.default')
control "gatherlogs.automate2.upgrade_failed" do
  impact 1.0
  title 'Check to see if Automate is reporting a failure during the hab sup upgrade process'
  desc "
It appears that there was a failure during the upgrade process for Automate, please
check the logs and contact support to see about getting this fixed.

#{upgrade_failed.summary}
  "

  describe upgrade_failed do
    its('last_entry') { should be_empty }
  end
end