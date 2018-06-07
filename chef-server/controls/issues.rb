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
    request_entity_413 = log_analysis(::File.join('var/log/opscode/nginx', logfile), 'HTTP/1\.\d" 413')
    describe request_entity_413 do
      it { should_not exist }
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
      it { should_not exist }
    end
  end
end


control "gatherlogs.chef-server.erchef-depsolver-startup-failure" do
  impact 1.0
  title 'Check for erchef startup errors for depsolver'
  desc "
  It appears that the erchef process if failing due to an error starting
  depsolver child processes.  This commonlly happens when the umask for root is
  set to something other than '0022' and a new gem is installed on the server.

  To find the gem causing the problem run the following command:
  find /opt/opscode/embedded/lib/ruby/gems -name \"*gemspec\" ! -perm -a+r

  And then fix it using:
  chmod 664 PATH/TO/GEMSPEC/FILE
  "

  common_logs.erchef do |logfile|
    erchef_depsolver = log_analysis("var/log/opscode/opscode-erchef/#{logfile}", '{{error,{shutdown,{failed_to_start_child,pooler_chef_depsolver_pool_sup,{shutdown,{failed_to_start_child,pooler,{{timeout,"unable to start members"}')
    describe erchef_depsolver do
      it { should_not exist }
    end
  end

  erchef_listener = log_analysis('ss_ontap.txt', '127.0.0.1:8000 ')
  describe erchef_listener do
    its('hits') { should cmp >= 1 }
  end
end
end
