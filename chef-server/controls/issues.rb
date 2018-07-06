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

  common_logs.nginx.each do |logfile|
    describe log_analysis(::File.join('var/log/opscode/nginx', logfile), 'HTTP/1\.\d" 413') do
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

  KB: https://getchef.zendesk.com/hc/en-us/articles/204381030-Troubleshoot-Cookbook-Dependency-Issues
  '

  common_logs.erchef do |logfile|
    depsolver = log_analysis("var/log/opscode/opscode-erchef/#{logfile}", "Supervisor pooler_chef_depsolver_member_sup had child chef_depsolver_worker started with {chef_depsolver_worker,start_link,undefined} at .* exit with reason killed in context child_terminated")

    describe depsolver do
      its('last_entry') { should be_empty }
    end
  end
end


control "gatherlogs.chef-server.erchef-depsolver-startup-failure" do
  impact 1.0
  title 'Check for erchef startup errors for depsolver'
  desc "
  It appears that the erchef process is not starting due to an error when starting
  the depsolver child processes.  This commonlly happens when the umask for root
  is set to something other than '0022' and a new gem is installed on the server.

  To find the gem causing the problem run the following command:
  find /opt/opscode/embedded/lib/ruby/gems -name \"*gemspec\" ! -perm -a+r

  And then fix it using:
  chmod 664 PATH/TO/GEMSPEC/FILE
  "

  common_logs.erchef do |logfile|
    erchef_depsolver = log_analysis("var/log/opscode/opscode-erchef/#{logfile}", '{{error,{shutdown,{failed_to_start_child,pooler_chef_depsolver_pool_sup,{shutdown,{failed_to_start_child,pooler,{{timeout,"unable to start members"}')
    describe erchef_depsolver do
      its('last_entry') { should be_empty }
    end
  end
end

# moved to a separate check as it's not a good indication of the depsolver problem.
control "gatherlogs.chef-server.erchef-depsolver-listening" do
  impact 1.0
  title 'Check for erchef process is listening on port 8000'
  desc "
  It appears that the erchef process is not listening on port 8000.  Please check
  the opscode-erchef logs to further determine what might be the problem.
  "

  erchef_listener = log_analysis('ss_ontap.txt', '127.0.0.1:8000 ')
  describe erchef_listener do
    its('hits') { should cmp >= 1 }
  end
end

control "gatherlogs.chef-server.rabbitmq-connection-failure" do
  impact 1.0
  title 'Check for erchef errors for rabbitmq connection errors'
  desc "
  It appears that the erchef process if having issues connecting to RabbitMQ.

  Please check that the connection details for RabbitMQ are correct and that
  there are no errors logged by RabbitMQ.
  "

  common_logs.erchef do |logfile|
    erchef_rabbitmq = log_analysis("var/log/opscode/opscode-erchef/#{logfile}", 'Could not connect, scheduling reconnect.", error: {{error,{badmatch,{error,{auth_failure_likely,{socket_closed_unexpectedly.*5672')
    describe erchef_rabbitmq do
      its('last_entry') { should be_empty }
    end
  end
end

control "gatherlogs.chef-server.erchef-bad_actor-permission-errors" do
  impact 1.0
  title 'Check erchef for permission errors related to bad_actor'
  desc "
  This usually indicates that a user has been disassociated from an organization
  or deleted completely from the chef-server.  In these cases it's possible for
  some permissions for that user to still exist on some objects in the organization.

  Users should not be added directly to objects and instead should be associated
  with groups that are then added to the permissions for objects.  This simplifies
  the clean up process when removing users.

  Search the opscode-erchef logs for `bad_actor` messages to find the user that
  is causing the error and remove them from all objects in the organization.
  "

  common_logs.erchef do |logfile|
    describe log_analysis("var/log/opscode/opscode-erchef/#{logfile}", 'status=400.*bad_actor') do
      its('last_entry') { should be_empty }
    end
  end
end

control "gatherlogs.chef-server.nginx-upstream-host-error" do
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
    describe log_analysis("var/log/opscode/nginx/#{logfile}", 'host not found in upstream') do
      its('last_entry') { should be_empty }
    end
  end
end

control "gatherlogs.chef-server.solr4-memory-allocation-error" do
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
    describe log_analysis("var/log/opscode/opscode-solr4/#{logfile}", 'Cannot allocate memory') do
      its('last_entry') { should be_empty }
    end
  end
end
