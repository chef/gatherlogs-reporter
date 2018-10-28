require 'mixlib/shellout'
require 'string/utf8'
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
      puts 'Debug enabled' if @debug
    end

    def debug?
      @debug
    end

    def zdclient
      puts 'Initializing Zendesk Client'
      logger = Logger.new(STDOUT)
      logger.level = Logger::ERROR

      @instance ||= ZendeskAPI::Client.new do |config|
        config.url = zdconfig[:url]
        config.username = zdconfig[:user]
        config.token = zdconfig[:token]
        config.retry = true
        config.logger = logger
      end
    end

    def valid_zendesk_request(url)
      uri = URI.parse(url)
      is_http_request?(uri) && uri.hostname == 'getchef.zendesk.com'
    end

    def valid_gatherlog_bundle(url)
      uri = URI.parse(url)
      params = CGI.parse(uri.query)
      extension = params['name'].first.split('.').last

      invalid_extensions = %w[log png jpg]
      !invalid_extensions.include?(extension)
    end

    def is_http_request?(uri)
      uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    end

    def check_logs(remote_url)
      return { error: 'Invalid URL', status: 1 } unless valid_zendesk_request(remote_url)
      return { error: 'Invalid gather-log bundle', status: 1 } unless valid_gatherlog_bundle(remote_url)

      cmd = ['check_logs', '--remote', remote_url]

      puts "[EXECUTING] #{cmd.join(' ')}"
      checklog = shellout(cmd)

      { results: checklog.stdout.utf8!, error: checklog.stderr.utf8!, status: checklog.exitstatus }
    end

    def shellout(cmd, options = {})
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

        unless debug?
          ZendeskAPI::Ticket.update!(zdclient,
                                     id: id,
                                     comment: { value: response, public: false })
        end
      end
    end

    def zendesk_comment_text(filename, output)
      output = 'No issues were found in the gather-log bundle' if output.empty?
      <<-EOC
Inspec gather-log results for: #{filename}

```
#{Paint.unpaint(output).utf8!}
```
      EOC
    end
  end
end
