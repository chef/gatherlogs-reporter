pushjobs = installed_packages('opscode-push-jobs-server')

%w{ access.log current error.log jobs.log }.each do |logfile|
  pushjobs_hostname = log_analysis("var/log/opscode/nginx/#{logfile}", 'host not found in upstream .* in /var/opt/opscode/nginx/etc/addon.d/10-push_jobs_upstreams.conf')

  control "gatherlogs.chef-server.push-jobs-server-hostname-misconfigured-#{logfile}" do
    title "Check for misconfiguration for hostname of push-jobs server"
    desc "
    Nginx is unable to communicate with the push-jobs service.

    This can happen if the hostname of the chef-server is changed but
    `opscode-push-jobs-server-ctl reconfigure` was not run to update the nginx
    configs.
    "

    tag summary: pushjobs_hostname.summary

    only_if { pushjobs.exists? && pushjobs_hostname.log_exists? }

    describe pushjobs_hostname do
      it { should_not exist }
    end
  end

  pushjobs_timestamp = log_analysis("var/log/opscode/opscode-pushy-server/#{logfile}", 'Bad timestamp in message')

  control "gatherlogs.chef-server.push-jobs-server-bad-timestamp-#{logfile}" do
    title "Check for messages about bad timestamps for push jobs clients"
    desc 'This usually indicates that a push-jobs client has an incorrect date/time set.'

    tag summary: pushjobs_timestamp.summary
    tag kb: 'https://getchef.zendesk.com/hc/en-us/articles/208496996-Push-Jobs-Jobs-Crashing-Consistently'

    only_if { pushjobs.exists? && pushjobs_timestamp.log_exists? }

    describe pushjobs_timestamp do
      it { should_not exist }
    end
  end
end
