require 'paint'

module Gatherlogs
  module Output
    FAILED = '#FF3333'.freeze
    GREEN = PASSED = '#32CD32'.freeze
    SKIPPED = '#BEBEBE'.freeze
    INFO = '#FF8C00'.freeze

    DESC_ICON = 'ⓘ'.freeze
    KB_ICON = '✩'.freeze
    SUMMARY_ICON = '⇨'.freeze

    PASSED_ICON = '✓'.freeze
    FAILED_ICON = '✗'.freeze
    SKIPPED_ICON = '↺'.freeze

    attr_accessor :logger

    def disable_colors
      @@colorize = false
    end

    def enable_colors
      @@colorize = true
    end

    def colorize(text, color)
      return text if color == :nothing
      @@colorize ? Paint[text, color] : text
    end

    def logger
      Gatherlogs.logger
    end

    def debug(*msg)
      if msg.last[0] == '#'
        color = msg.pop
      else
        color = INFO
      end
      logger.debug(colorize msg.join(' ').chomp, color)
    end

    def info(*msg)
      if msg.last[0] == '#'
        color = msg.pop
      else
        color = GREEN
      end
      logger.info(colorize msg.join(' ').chomp, color)
    end

    def error(*msg)
      if msg.last[0] == '#'
        color = msg.pop
      else
        color = FAILED
      end
      logger.error(colorize msg.join(' ').chomp, color)
    end

    def truncate(text, length = 700)
      text[0..(length-1)]
    end

    # Make sure that we tab over the output for multiline text so that it lines
    # up with the rest of the output.
    def tabbed_text(text, spaces = 0)
      Array(text).join("\n").gsub("\n", "\n#{' ' * (4 + spaces.to_i)}")
    end

    def labeled_output(label, output, override_colors = {})
      colors = { label: INFO, output: :nothing }.merge(override_colors)

      label_output = colorize(label, colors[:label])

      "#{label_output} #{colorize output, colors[:output]}"
    end

    # Print out detailed info for each test subsection
    # For example the description, summary or kb info provided in the control
    def subsection(output)
      '  ' + output unless output.nil? || output.empty?
    end
  end
end
