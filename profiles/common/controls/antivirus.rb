control 'gatherlogs.common.antivirus_check' do
  title 'Check to see if any antivirus agents are running on the system'
  desc "
The system is running an Antivirus agent, this is just an advisory message as
occasionally these agents can interfere with or slow down internal processes."

  # symantec - Symantec AV
  # savd - Sophos AV
  # ds_agent - TrendMicro
  %w[symantec ds_agent savd].each do |av_agent|
    agent_log = log_analysis('ps_fauxww.txt', av_agent)
    tag summary: agent_log.summary unless agent_log.empty?

    describe agent_log do
      its('last_entry') { should be_empty }
    end
  end
end
