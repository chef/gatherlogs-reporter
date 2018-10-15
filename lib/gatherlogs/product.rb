module Gatherlogs
  class Product
    PRODUCT_MATCHES = {
      'automate' => 'delivery-ctl-status.txt',
      'chef-server' => 'private-chef-ctl_status.txt',
      'automate2' => 'chef-automate_status.txt',
      'chef-backend' => 'chef-backend-ctl-status.txt'
    }

    def self.detect(log_path)
      return unless File.directory?(log_path)

      Dir.chdir(log_path) do
        PRODUCT_MATCHES.each do |k,filename|
          return k if File.exists?(filename)
        end
      end
    end
  end
end
