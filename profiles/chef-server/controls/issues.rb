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

control 'gatherlogs.chef-server.solr4_heap_size' do
  title 'Check solr4 for errors related to the heap size'
  desc "
SOLR4 tried to allocate more memory than was available in the configured heap size.

You will need to inscrease the heap configuration by setting
`opscode_solr4['heap_size']` in `/etc/opscode/chef-server.rb`.  Please ensure
that this value is no more than 50% of the total RAM and less than 8192, which
ever value is smaller.

You will also need to make sure that there is enough free memory available on
the system to increase this value, if not you will also need ot upgrade the
amount of RAM allocated to this system.
  "

  common_logs.solr4 do |logfile|
    solr = log_analysis(
      "var/log/opscode/opscode-solr4/#{logfile}",
      'Caused by: java.lang.OutOfMemoryError: Java heap space'
    )

    tag summary: solr.summary unless solr.empty?
    describe solr do
      its('last_entry') { should be_empty }
    end
  end
end

control 'gatherlogs.chef-server.solr4-memory-allocation-error' do
  title 'Check solr4 for errors related to memory allocations'
  desc "
SOLR4 service is unable to allocate enough memory to operate correctly. Please
make sure that the system has not run out of physical RAM or swap space.

If `opscode_solr4['heap_size']` is specified in `/etc/opscode/chef-server.rb`
Please ensure that this value is no more than 50% of the total RAM and less
than 8192, which ever value is smaller.
  "

  common_logs.solr4 do |logfile|
    solr = log_analysis(
      "var/log/opscode/opscode-solr4/#{logfile}",
      'Cannot allocate memory'
    )

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

control 'gatherlogs.chef-server.cookbook_segment_request_api_error' do
  title 'Check to see if there are errors uploading cookbooks'
  desc "
erchef is reporting errors during cookbook upload due to an invalid api version
being specified. Chef-Server 12.18.14 added a new segment free api for cookbook
uploads and some older versions of tools do not properly send the correct API
version.

Which means that Berkshelf >= 7.0.5 and ChefDK >= 3.2.30
should be used.
"

  common_logs.erchef do |logfile|
    cookbook_upload = log_analysis(
      "var/log/opscode/opscode-erchef/#{logfile}",
      'invalid_key,<<"all_files">>.*req_api_version=1'
    )
    tag summary: cookbook_upload.summary unless cookbook_upload.empty?
    describe cookbook_upload do
      its('last_entry') { should be_empty }
    end
  end
end

control 'gatherlogs.chef-server.keygen_timeout_issue' do
  title 'Check to see if there are any timeout errors generating openssl keys'
  desc "
erchef is reporting timeout errors while trying to generate keys for the keygen
cache.  This usually indicates that there is a high load on the system or the
file IO is unable to keep up with writing the keys to disk.

To workaround this issue increase the keygen timeout config in /etc/opscode/chef-server.rb:

opscode_erchef['keygen_timeout'] = 5000
"

  common_logs.erchef do |logfile|
    keygen_timeout = log_analysis(
      "var/log/opscode/opscode-erchef/#{logfile}",
      'chef_keygen_cache,keygen_timeout'
    )
    tag summary: keygen_timeout.summary unless keygen_timeout.empty?
    describe keygen_timeout do
      its('hits') { should cmp <= 20 }
    end
  end
end

control 'gatherlogs.chef-server.rabbitmq_access_error' do
  title 'Check to see if rabbmit mq is having error accessing files'
  desc '
  Rabbitmq is reporting an issue accessing some file(s), please check the
  log output to see what file is causing issues.

  Common causes:
  1. Permission issues with ssl certificates
  2. Corrupted rabbmitmq database files
  '

  rmq_access_error = log_analysis(
    'var/opt/opscode/rabbitmq/log/rabbit@localhost.log',
    '{error,eacces}'
  )

  tag summary: rmq_access_error.summary
  describe rmq_access_error do
    its('last_entry') { should be_empty }
  end
end

control 'gatherlogs.common.too_many_openssl_processes_running' do
  title 'Check to see if there are too many openssl genrsa processes running'
  desc "
If the chef-server keygen has issues populating the cache it may leave several
openssl genrsa processes behind.  This will cause a high amount of cpu load on the system and may
interfere with the operation of other chef-server processes."

  openssl_processes = log_analysis('ps_fauxww.txt', 'openssl genrsa')
  tag summary: openssl_processes.summary unless openssl_processes.empty?

  describe openssl_processes do
    its('hits') { should cmp <= 10 }
  end
end
