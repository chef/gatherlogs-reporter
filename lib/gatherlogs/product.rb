module Gatherlogs
  class Product
    def self.detect(log_path)
      return unless File.directory?(log_path)

      products = {
        'automate' => 'delivery-ctl-status.txt',
        'chef-server' => 'private-chef-ctl_status.txt',
        'automate2' => 'chef-automate_status.txt',
        'chef-backend' => 'chef-backend-ctl-status.txt'
      }
      products.each do |product,filename|
        full_path = File.join(log_path, filename)
        return product if File.exists?(full_path)
      end

      return nil
    end
  end
end
