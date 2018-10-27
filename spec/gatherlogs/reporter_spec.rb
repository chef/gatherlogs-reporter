RSpec.describe Gatherlogs::Reporter do
  let(:reporter) do
    r = Gatherlogs::Reporter.new({})
    r.disable_colors
    r
  end

  let(:success_result) do
    {
      'status' => 'success',
      'code_desc' => 'CODE_DESC',
      'message' => 'Something failed',
      'skip_message' => 'We skipped it'
    }
  end

  let(:failed_result) do
    {
      'status' => 'failed',
      'code_desc' => 'CODE_DESC',
      'message' => 'Something failed',
      'skip_message' => 'We skipped it'
    }
  end

  let(:skipped_result) do
    {
      'status' => 'skipped',
      'code_desc' => 'CODE_DESC',
      'message' => 'Something failed',
      'skip_message' => 'We skipped it'
    }
  end

  it "should return nil if no text" do
    expect(reporter.desc_text({})).to eq nil
    expect(reporter.desc_text({ 'desc' => '' })).to eq nil

    expect(reporter.kb_text({ 'tags' => {} })).to eq nil
    expect(reporter.summary_text({ 'tags' => {} })).to eq nil
  end

  it 'should return desc text' do
    simple = { 'desc' => 'Description text' }
    expect(reporter.desc_text(simple)).to eq "#{Gatherlogs::Output::DESC_ICON} Description text\n"
  end

  it 'should return desc text' do
    simple = { 'tags' => { 'summary' => 'Summary text' } }
    expect(reporter.summary_text(simple)).to eq "#{Gatherlogs::Output::SUMMARY_ICON} Summary text\n"
  end

  it 'should process profiles' do
    allow(reporter).to receive(:process_profile).with({ 'controls' => ['something'] }) {
      { report: ['a report'], system_info: {} }
    }
    allow(reporter).to receive(:process_profile).with({ 'controls' => ['something else'] }) {
      { report: ['b report'], system_info: {} }
    }

    expect(
      reporter.report({
        'profiles' => [{
          'controls' => ['something']
        }, {
          'controls' => ['something else']
        }]
      })
    ).to match({ report: ['a report', 'b report'], system_info: {} })
  end

  it 'should not process profiles with no controls' do
    expect(
      reporter.report({ 'profiles' => [{ 'controls' => [] }] })
    ).to match({ report: [], system_info: {} })
  end

  it 'should return kb link text' do
    single = { 'tags' => { 'kb' => 'https://test.com' }}
    array = { 'tags' => { 'kb' => ['https://test.com', 'http://google.com'] }}
    expect(reporter.kb_text(single)).to eq "#{Gatherlogs::Output::KB_ICON} https://test.com\n"
    expect(reporter.kb_text(array)).to eq "#{Gatherlogs::Output::KB_ICON} https://test.com\n    http://google.com\n"
  end

  it "should return control info with label" do
    expect(reporter.control_info('>', 'testing', 'green')).to eq "> testing"
  end

  it "should return correct result message for success" do
    expect(reporter.format_result_message(success_result)).to eq "✓ CODE_DESC"
  end

  it "should return correct result message for skipped" do
    expect(reporter.format_result_message(skipped_result)).to eq "↺ We skipped it"
  end

  it "should return correct result message for failed" do
    expect(reporter.format_result_message(failed_result)).to eq "✗ CODE_DESC\n    Something failed"
  end

  it "should set args" do
    reporter = Gatherlogs::Reporter.new({ show_all_controls: true, show_all_tests: true })

    expect(reporter.show_all_controls).to eq true
    expect(reporter.show_all_tests).to eq true
  end
end
