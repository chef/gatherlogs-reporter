require 'mixlib/shellout'
require 'string/utf8'
require 'zendesk_api'
require 'cgi'
require 'faraday'
require 'fileutils'

module Grese
  class WebhookServer
    attr_accessor :glconfig

    def initialize(config, debug = false)
      @debug = debug
      @glconfig = config
      zdclient
       puts '===========================Debug enabled' if @debug
    end

    def debug?
      @debug
    end

    def zdclient
      # puts 'Initializing Zendesk Client'
      logger = Logger.new(STDOUT)
      logger.level = Logger::ERROR

      @zdclient ||= ZendeskAPI::Client.new do |config|
        config.url = glconfig[:url]
        config.username = glconfig[:user]
        config.token = glconfig[:token]
        config.retry = true
        config.logger = logger
      end
    end

    # parse sendsafely links from a ticket body
    def parseLinks(body)
      links = body.match(/(https:\/\/[a-zA-Z\.]+\/receive\/\?[A-Za-z0-9&=\-]+packageCode=[A-Za-z0-9\-_]+#keyCode=[A-Za-z0-9\-_]+)/)
    end
    
    def valid_zendesk_request(url)
      uri = URI.parse(url)
      http_request?(uri) && uri.hostname == 'getchef.zendesk.com'
    end

    def valid_gatherlog_bundle(url)
      uri = URI.parse(url)
      params = CGI.parse(uri.query)
      extension = params['name'].first.split('.').last

      invalid_extensions = %w[log png jpg txt]
      !invalid_extensions.include?(extension)
    end

    def http_request?(uri)
      uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    end
    
    def check_logs(remote_url)
      unless valid_zendesk_request(remote_url)
        return { error: 'Invalid URL', status: 1 }
      end
      unless valid_gatherlog_bundle(remote_url)
        return { error: 'Invalid gather-log bundle', status: 1 }
      end

      cmd = ['gatherlog', 'report', '-m', '--remote', remote_url]

#      puts "[EXECUTING] #{cmd.join(' ')}"
      checklog = shellout(cmd)

      {
        results: checklog.stdout.utf8!,
        error: checklog.stderr.utf8!,
        status: checklog.exitstatus
      }
    end

    def check_link(link,ticket_id)
        all_results = []      
        # parse out package code, package id, etc
        thread = link.split("thread=").last.split("&packageCode").first
        packageCode = link.split("&packageCode=").last.split("#keyCode").first
        keyCode = link.split("#keyCode=").last
        
        # api request to sendsafely to get package details
        package = get_package_info(thread)
        
        # get server secret
        serverSecret = package['serverSecret']
        packageCode = package['packageCode']
        out = package['files']

        if package['files']

          working_dir = glconfig[:workingDir]
          ticket_dir = "#{working_dir}/#{ticket_id}"
          
          # for each file in package
          package['files'].each do |file|

            # decrypt file from s3 store and place in working dir
            decrypted_file = decrypt(file,serverSecret+keyCode,ticket_id)

            # run gatherlogs profiles against file
            cmd = ['gatherlog', 'report', '-p', decrypted_file]
            cmd = ['hab','pkg','exec','chef/gatherlogs_reporter','gatherlog', 'report', '-p', decrypted_file]
            checklog = shellout(cmd)
            
            # add to results array
            all_results.push( "filename" => file['fileName'],
                              "report" => {
                                 results: checklog.stdout.utf8!,
                                 error: checklog.stderr.utf8!,
                                 status: checklog.exitstatus
                               }
                            )

            # remove decrypted file?
            cmd = ["rm",decrypted_file]
            rm_out =  shellout(cmd)
            
          end
          #remove working dir?
          cmd = ["rm","-rf",ticket_dir]
          rm_out =  shellout(cmd)
            
        else
          return "No files found."
        end
        
        return all_results
        
    end
    
    def decrypt(file, secret, ticket_id)

      # variablize these
      
      mountpoint = glconfig[:ssS3Mountpoint]
      sendsafely_path = glconfig[:ssS3Path]
      working_dir = glconfig[:workingDir]

      path = mountpoint + sendsafely_path
      ticket_dir = "#{working_dir}/#{ticket_id}"

      FileUtils.mkdir_p ticket_dir
      
      (1..file['parts']).each do |n|

        part = "#{path}/#{file['fileId']}-#{n}"


        cmd = ["gpg","--batch","--yes","--passphrase",secret,"--output",ticket_dir+"/#{file['fileId']}-#{n}","--decrypt",part]
        decrypt_out = shellout(cmd)
        
        results= {
          results: decrypt_out.stdout.utf8!,
          error: decrypt_out.stderr.utf8!,
          status: decrypt_out.exitstatus
        }
      end

      cmd = "cat "
      (1..file['parts']).each do |n|
        cmd = cmd + ticket_dir+ "/#{file['fileId']}-#{n}"
      end

      cmd = cmd + " >> "
      cmd = cmd + ticket_dir + "/" + file['fileName']

      concat_out = shellout(cmd)

      results= {
        results: concat_out.stdout.utf8!,
        error: concat_out.stderr.utf8!,
        status: concat_out.exitstatus
      }

      #check for errors? idgaf
      return ticket_dir + "/" + file['fileName']
    end
    
    def get_package_info(thread)
      url = glconfig[:ssApiHost]
      apiPath = glconfig[:ssApiPath]
      ssApiKey = glconfig[:ssApiKey]
      ssApiSecret = glconfig[:ssApiSecret]
      
      timestamp = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S+0000")
#      packagepath = "https://" + url + apiPath + "/package/#{thread}"
      
      output = Faraday.new("https://" + url + apiPath + "/package/#{thread}", headers: {
                             'ss-api-key' => ssApiKey,
                             'ss-request-timestamp' => timestamp,
                             'ss-request-signature' => OpenSSL::HMAC.hexdigest("SHA256", ssApiSecret, ssApiKey+apiPath+"/package/#{thread}"+timestamp),
                           }).get.body

      JSON.parse(output)
    end
    
    def shellout(cmd, options = {})
      shell = Mixlib::ShellOut.new(cmd, options)
      shell.run_command
      shell
    end

    def update_zendesk(id, filename, results)
      return if results[:status] != 0

      response = zendesk_comment_text(filename, results[:results].chomp)

      puts "Updating zendesk ticket #{id} with\n#{response}" if debug?

      unless debug? # rubocop:disable Style/GuardClause
        ZendeskAPI::Ticket.update!(
          zdclient, id: id, comment: { value: response, public: false }
        )
      end
    end

    def zendesk_comment_text(filename, output)
      output = 'No issues were found in the gather-log bundle' if output.empty?
      <<~EOC
        Inspec gather-log results for: #{filename}

        ```
        #{output.utf8!}
        ```
      EOC
    end
  end
end
