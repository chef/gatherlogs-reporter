module Gatherlogs
  class CLI
    def initialize(args)
      parse_args(args)

      @reporter = Gatherlogs::Reporter.new({
        all_controls: @all_controls,
        verbose: @verbose,
        log_level: @log_level
      })
    end

    def parse_args(args)
      while flag = args.shift
        case flag
        when '-d', '--debug'
          @log_level = :debug
        when '-a', '--all'
          @all_controls = true
        when '-v', '--verbose'
          @verbose = true
        end
      end
    end

    def report_from_stdin
      @reporter.report(JSON.parse(STDIN.read))
    end
  end
end
