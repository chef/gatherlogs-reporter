pushjobs = installed_packages('opscode-push-jobs-server')

%w{ access.log current error.log }.each do |logfile|
  pushjobs_hostname = log_analysis("var/log/opscode/nginx/#{logfile}", 'host not found in upstream .* in /var/opt/opscode/nginx/etc/addon.d/10-push_jobs_upstreams.conf')

  control "gatherlogs.chef-server.push-jobs-server-hostname-misconfigured-#{logfile}" do
    title "Check for misconfiguration for hostname of push-jobs server"
    desc "
    Nginx is unable to communicate with the push-jobs service.

    Found: #{pushjobs_hostname.first}

    This can happen if the hostname of the chef-server is changed but
    `opscode-push-jobs-server-ctl reconfigure` was not run to update the nginx
    configs.
    "

    impact 1.0

    only_if { pushjobs.exists? }

    describe pushjobs_hostname do
      it { should_not exist }
    end
  end
end
