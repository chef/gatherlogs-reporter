RSpec.describe Gatherlogs::Reporter do
  before do
    Gatherlogs.logger = double('logger', info: true, error: true, debug: true)
    # Gatherlogs.logger.disable_colors
  end

  let(:reporter) do
    Gatherlogs::Reporter.new({})
  end

  it 'should process profiles' do
    allow(reporter).to receive(:process_profile).with('controls' => ['something']) {
      { report: ['a report'], system_info: {} }
    }
    allow(reporter).to receive(:process_profile).with('controls' => ['something else']) {
      { report: ['b report'], system_info: {} }
    }

    expect(
      reporter.report(
        'profiles' => [{
          'controls' => ['something']
        }, {
          'controls' => ['something else']
        }]
      )
    ).to match(report: ['a report', 'b report'], system_info: {})
  end

  it 'should not process profiles with no controls' do
    expect(
      reporter.report('profiles' => [{ 'controls' => [] }])
    ).to match(report: [], system_info: {})
  end

  it 'should set args' do
    reporter = Gatherlogs::Reporter.new(show_all_controls: true, show_all_tests: true)

    expect(reporter.show_all_controls).to eq true
    expect(reporter.show_all_tests).to eq true
  end

  it 'should generate a blank report if there are no controls' do
    expect(Gatherlogs::ControlReport).to receive(:new).with([], {}) { double('results', system_info: {}, report: []) }
    expect(reporter.process_profile('controls' => [])).to eq(system_info: {}, report: [])
  end

  it 'should pass the show_all_controls to the control report' do
    reporter = Gatherlogs::Reporter.new(show_all_controls: true)
    expect(Gatherlogs::ControlReport).to receive(:new).with([], show_all_controls: true) { double('results', system_info: {}, report: []) }
    expect(reporter.process_profile('controls' => [])).to eq(system_info: {}, report: [])
  end

  it 'should pass the show_all_tests to the control report' do
    reporter = Gatherlogs::Reporter.new(show_all_tests: true)
    expect(Gatherlogs::ControlReport).to receive(:new).with([], show_all_tests: true) { double('results', system_info: {}, report: []) }
    expect(reporter.process_profile('controls' => [])).to eq(system_info: {}, report: [])
  end
end
