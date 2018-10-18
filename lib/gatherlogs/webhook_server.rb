require 'mixlib/shellout'
require "string/utf8"
require 'zendesk_api'
require 'paint'

module Gatherlogs
  class WebhookServer
    attr_accessor :zdconfig

    def initialize(config)
      @zdconfig = config
      zdclient
    end

    def zdclient
      puts "Initializing Zendesk Client"
      @instance ||= ZendeskAPI::Client.new do |config|
        config.url = zdconfig[:url]
        config.username = zdconfig[:user]
        config.token = zdconfig[:token]
        config.retry = true
        config.logger = Logger.new(STDOUT)
      end
    end

    def validate_url(url)
      uri = URI.parse(url)
      uri.kind_of?(URI::HTTP) || uri.kind_of?(URI::HTTPS)
    end

    def check_logs(remote_url)
      return { error: 'Invalid URL', status: 1 } unless validate_url(remote_url)

      cmd = ['check_logs', '--remote', remote_url]

      puts "[EXECUTING] #{cmd.join(' ')}"
      checklog = shellout(cmd)

      { results: checklog.stdout.utf8!, error: checklog.stderr.utf8!, status: checklog.exitstatus }
    end

    def shellout(cmd, options={})
      shell = Mixlib::ShellOut.new(cmd, options)
      shell.run_command
      shell
    end

    def invalid_request
      status 400
    end

    def update_zendesk(id, filename, results)
      if results[:status] != 1
        response = zendesk_comment_text(filename, results[:results])
        ZendeskAPI::Ticket.update!(zdclient, {
          id: id,
          comment: { value: response, public: false }
        })
      end
    end

    def zendesk_comment_text(filename, output)
<<-EOC
CheckLog results from: #{filename}

```
#{Paint.unpaint(output).utf8!}
```
EOC
    end
  end
end
