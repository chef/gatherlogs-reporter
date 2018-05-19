# you add controls here
control 'gatherlogs.chef-server.413-request-entity-too-large' do
  impact 0.5
  title 'Check for request entity too large in nginx logs'
  desc '
  Found 413 "Request Entity Too Large" errors in the logs, this typically
  occurs when chef-clients attempt to submit large node data sets to the
  chef-server.

  Possible causes include:
    * Ohai Passwd plugin on systems that use LDAP/AD authentication
    * Ohai Session plugin on systems with stale logins
    * Clients using the Audit cookbook to submit compliance data.

  For possible resolutions see: https://getchef.zendesk.com/hc/en-us/articles/115002333646-Known-Issues
  '

  %w{ access.log current }.each do |logfile|
    describe file(::File.join('var/log/opscode/nginx', logfile)) do                  # The actual test
      its('content') { should_not match(%r{HTTP/1\.\d" 413}) }
    end
  end
end
