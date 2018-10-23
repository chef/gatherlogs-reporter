require 'mixlib/shellout'
require "string/utf8"
require 'zendesk_api'
require 'paint'
require 'cgi'

module Gatherlogs
  class WebhookServer
    attr_accessor :zdconfig

    def initialize(config, debug = false)
      @debug = debug
      @zdconfig = config
      zdclient
    end

    def debug?
      @debug
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

    def validate_zendesk_url(url)
      uri = URI.parse(url)
      if uri.kind_of?(URI::HTTP) || uri.kind_of?(URI::HTTPS)
        return url.hostname == 'getchef.zendesk.com'
      end
    end

    def decode_url(url)
      uri = URI.parse(url)
      params = CGI::parse(uri.query)

      { hostname: uri.hostname, name: }
    end

    def check_logs(remote_url)
      return { error: 'Invalid URL', status: 1 } unless validate_zendesk_url(remote_url)

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
        response = zendesk_comment_text(filename, results[:results].chomp)

        puts "Updating zendesk ticket #{id} with\n#{response}" if debug?

        ZendeskAPI::Ticket.update!(zdclient, {
          id: id,
          comment: { value: response, public: false }
        }) unless debug?
      end
    end

    def zendesk_comment_text(filename, output)
      output = "No issues were found in the gather-log bundle" if output.empty?
<<-EOC
Inspec gather-log results for: #{filename}

```
#{Paint.unpaint(output).utf8!}
```
EOC
    end
  end
end
