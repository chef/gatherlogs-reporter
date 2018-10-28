require 'mixlib/shellout'

module Gatherlogs
  module Shellout
    def shellout!(cmd, options={})
      # Gatherlogs.debug "Executing '#{Array(cmd).join(' ')}'"
      shell = Mixlib::ShellOut.new(cmd, options)
      shell.run_command
      shell.error!
      shell
    end
  end
end
