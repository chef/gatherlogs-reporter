# Checking presence of checksum: <<"aec79664a83e5086e738ab8659c81399">> for org <<"654cafca20690e27f34035e3e0a558ef">> from bucket "bookshelf" has taken longer than 5000 ms

control 'gatherlogs.chef-server.erchef_bookshelf_errors' do
  title 'Checking presence of checksum timeout for bookshelf'
  desc "
opscode-erchef is reporting timeouts while trying to check for cookbook file checksums.

Please check for the following issues:
1. DNS resolution works for all DNS servers in `/etc/resolv.conf` or equiv
2. Correct hostname resolution
3. Correct api_fqdn settings in /etc/opscode/chef-server.rb

Please contact support to get this problem resolved"

  common_logs.erchef do |logfile|
    erchef_bookshelf = log_analysis("var/log/opscode/opscode-erchef/#{logfile}", 'Checking presence of checksum: .* from bucket "bookshelf" has taken longer than 5000 ms')
    tag summary: erchef_bookshelf.summary unless erchef_bookshelf.empty?
    describe erchef_bookshelf do
      its('last_entry') { should be_empty }
    end
  end
end

control 'gatherlogs.chef-server.erchef-bad_actor-permission-errors' do
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
    bad_actor = log_analysis("var/log/opscode/opscode-erchef/#{logfile}", 'status=400.*bad_actor')
    tag summary: bad_actor.summary unless bad_actor.empty?
    describe bad_actor do
      its('last_entry') { should be_empty }
    end
  end
end

control 'gatherlogs.chef-server.erchef-depsolver-startup-failure' do
  impact 'high'
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
    tag summary: erchef_depsolver.summary unless erchef_depsolver.empty?
    describe erchef_depsolver do
      its('last_entry') { should be_empty }
    end
  end
end

# moved to a separate check as it's not a good indication of the depsolver problem.
control 'gatherlogs.chef-server.erchef-depsolver-listening' do
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

error_limit = 100
control 'gatherlogs.chef-server.erchef-500-errors' do
  title 'Check for a large number of 500 errors being returned from erchef'
  desc "
  Found more than #{error_limit} number of messages with status=500 errors,
  please review the logs for errors and contact support.
  "

  common_logs.erchef do |logfile|
    erchef_errors = log_analysis("var/log/opscode/opscode-erchef/#{logfile}", 'status=500')
    tag summary: erchef_errors.summary unless erchef_errors.empty?
    describe erchef_errors do
      its('count') { should < error_limit }
    end
  end
end
