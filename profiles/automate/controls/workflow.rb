# you add controls here
control 'gatherlogs.automate.runner_worker_terminated' do
  impact 0.5
  title 'Check to see the runner process was terminated'
  desc '
The Automate process that manage workers information was terminated.

To resolve this issue restart the delivery service.
  '

  %w[console.log current].each do |logfile|
    runner_worker_terminated = log_analysis(::File.join('var/log/delivery/delivery', logfile), 'terminated with reason:.*jobs_queue')
    tag summary: runner_worker_terminated.summary unless runner_worker_terminated.empty?

    describe runner_worker_terminated do # The actual test
      its('last_entry') { should be_empty }
    end
  end
end
