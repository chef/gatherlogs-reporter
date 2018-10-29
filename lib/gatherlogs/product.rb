module Gatherlogs
  class Product
    def self.detect(log_path)
      return unless File.directory?(log_path)

      products = {
        'delivery-ctl-status.txt' => 'automate',
        'private-chef-ctl_status.txt' => 'chef-server',
        'chef-automate_status.txt' => 'automate2',
        # fall back in case they are using gather-logs local mode
        'journalctl_chef-automate.txt' => 'automate2',
        'chef-backend-ctl-status.txt' => 'chef-backend'
      }
      products.each do |filename, product|
        full_path = File.join(log_path, filename)
        return product if File.exist?(full_path)
      end

      nil
    end
  end
end
