module Gatherlogs
  class Product
    def self.detect(log_path)
      return unless File.directory?(log_path)

      Dir.chdir(log_path) do
        return 'automate' if File.exists?('delivery-ctl-status.txt')
        # Disable for now, just treat as a chef-server
        # return 'chef-legacy-ha' if File.exists?('private-chef-ctl_ha-status.txt')
        return 'chef-server' if File.exists?('private-chef-ctl_status.txt')
        return 'automate2' if File.exists?('chef-automate_status.txt')
        return 'chef-backend' if File.exists?('chef-backend-ctl-status.txt')
      end
    end
  end
end
