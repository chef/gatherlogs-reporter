control 'gatherlogs.common.antivirus_check' do
  title 'Check to see if any antivirus agents are running on the system'
  desc "
The system is running an Antivirus agent, this isn't strictly an errors and
instead just an advisory message as sometimes these agents can interfere with
some internal processes."

  %w{ symantec ds_agent }.each do |av_agent|
    agent_log = log_analysis('ps_fauxww.txt', av_agent)
    tag summary: agent_log.summary unless agent_log.empty?

    describe agent_log do
      its('last_entry') { should be_empty }
    end
  end
end
