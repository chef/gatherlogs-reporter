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
  '

  tag kb: 'https://docs.chef.io/config_rb_server.html#large-node-sizes'
  tag kb: 'https://getchef.zendesk.com/hc/en-us/articles/115002333646-Known-Issues'

  common_logs.nginx.each do |logfile|
    nginx413 = log_analysis(::File.join('var/log/opscode/nginx', logfile), 'HTTP/1\.\d" 413')
    tag summary: nginx413.summary unless nginx413.empty?
    describe nginx413 do
      its('last_entry') { should be_empty }
    end
  end
end

control 'gatherlogs.chef-server.depsolver-timeouts' do
  impact 1.0
  title 'Check for depsolver timeouts'
  desc '
  It appears that depsolver is being killed and causing a failure to
  complete the cookbook run_list calculation in the allotted time.
  Chef-client runs may report this as 412/503 API errors.
  '

  tag kb: 'https://getchef.zendesk.com/hc/en-us/articles/204381030-Troubleshoot-Cookbook-Dependency-Issues'

  common_logs.erchef do |logfile|
    depsolver = log_analysis("var/log/opscode/opscode-erchef/#{logfile}", 'Supervisor pooler_chef_depsolver_member_sup had child chef_depsolver_worker started with {chef_depsolver_worker,start_link,undefined} at .* exit with reason killed in context child_terminated')
    tag summary: depsolver.summary unless depsolver.empty?
    describe depsolver do
      its('last_entry') { should be_empty }
    end
  end
end

control 'gatherlogs.chef-server.rabbitmq-connection-failure' do
  impact 1.0
  title 'Check for erchef errors for rabbitmq connection errors'
  desc "
  It appears that the erchef process if having issues connecting to RabbitMQ.

  Please check that the connection details for RabbitMQ are correct and that
  there are no errors logged by RabbitMQ.
  "

  common_logs.erchef do |logfile|
    erchef_rabbitmq = log_analysis("var/log/opscode/opscode-erchef/#{logfile}", 'Could not connect, scheduling reconnect.", error: {{error,{badmatch,{error,{auth_failure_likely,{socket_closed_unexpectedly.*5672')
    tag summary: erchef_rabbitmq.summary unless erchef_rabbitmq.empty?
    describe erchef_rabbitmq do
      its('last_entry') { should be_empty }
    end
  end
end

control 'gatherlogs.chef-server.nginx-upstream-host-error' do
  impact 1.0
  title 'Check nginx for errors related to upstream hosts'
  desc "
  NGINX is reporting issues finding the host for an upstream service.  This could
  indicate that there is an issue for the given DNS entry or that server hostname
  changed but needs `chef-server-ctl reconfigure` run to pick up the changes.

  NGINX will also cache IPs resolved from DNS entries until the service is restarted
  so it may also be necessary to run `chef-server-ctl restart nginx` for it to pick
  up changes to DNS records.
  "

  common_logs.nginx do |logfile|
    nginx = log_analysis("var/log/opscode/nginx/#{logfile}", 'host not found in upstream')
    tag summary: nginx.summary unless nginx.empty?
    describe nginx do
      its('last_entry') { should be_empty }
    end
  end
end

control 'gatherlogs.chef-server.solr4-memory-allocation-error' do
  impact 1.0
  title 'Check solr4 for errors related to memory allocations'
  desc "
SOLR4 service is unable to allocate enough memory to operate correctly. Please
make sure that the system has not run out of physical RAM or swap space.

If `opscode_solr4['heap_size']` is specified in `/etc/opscode/chef-server.rb` ensure
that this value is no more than 50% of the total RAM and less than 8192, which ever value
is smaller.
  "

  common_logs.solr4 do |logfile|
    solr = log_analysis("var/log/opscode/opscode-solr4/#{logfile}", 'Cannot allocate memory')
    tag summary: solr.summary unless solr.empty?
    describe solr do
      its('last_entry') { should be_empty }
    end
  end
end

control 'gatherlogs.chef-server.oc_id_unable_to_start' do
  title 'Check that the oc_id service is not having trouble starting'
  desc "
If a stale service.pid file is left behind the oc_id service will be unable to
start even though the runsv process manager keeps trying to start it up.

To fix the you will need to remove the offending server.pid file.
"

  oc_id = log_analysis('var/log/opscode/oc_id/current', 'A server is already running. Check .*server.pid')
  tag summary: oc_id.summary

  describe oc_id do
    its('last_entry') { should be_empty }
  end
end
