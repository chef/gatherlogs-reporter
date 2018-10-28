RSpec.describe Gatherlogs::ControlReport do
  let(:reporter) do
    Gatherlogs::ControlReport.new([{
                                    'id' => '010.d.e.f',
                                    'tags' => {
                                      'summary' => 'Summary text',
                                      'system' => { 'test' => 'foo' },
                                      'kb' => ['https://test.com', 'http://google.com']
                                    },
                                    'desc' => 'DEF Description text',
                                    'results' => [{
                                      'status' => 'success',
                                      'code_desc' => 'It worked!'
                                    }, {
                                      'status' => 'failed',
                                      'code_desc' => 'Control Source Code Error'
                                    }]
                                  }, {
                                    'id' => '000.a.b.c',
                                    'tags' => { 'verbose' => true },
                                    'desc' => 'ABC Description text',
                                    'results' => [{
                                      'status' => 'failed',
                                      'code_desc' => 'Missing all the things'
                                    }]
                                  }, {
                                    'id' => '010.a.b.c',
                                    'tags' => {},
                                    'desc' => 'ABC2 Description text',
                                    'results' => [{
                                      'status' => 'skipped',
                                      'code_desc' => 'Skipped because of reasons'
                                    }]
                                  }], false, false)
  end

  before do
    reporter.disable_colors
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

  it 'should return nil if no text' do
    expect(reporter.desc_text({})).to eq nil
    expect(reporter.desc_text('desc' => '')).to eq nil

    expect(reporter.kb_text('tags' => {})).to eq nil
    expect(reporter.summary_text('tags' => {})).to eq nil
  end

  it 'should return desc text' do
    simple = { 'desc' => 'Description text' }
    expect(reporter.desc_text(simple)).to eq "#{Gatherlogs::Output::DESC_ICON} Description text\n"
  end

  it 'should return summary text' do
    simple = { 'tags' => { 'summary' => 'Summary text' } }
    expect(reporter.summary_text(simple)).to eq "#{Gatherlogs::Output::SUMMARY_ICON} Summary text\n"
  end

  it 'should return kb link text' do
    single = { 'tags' => { 'kb' => 'https://test.com' } }
    array = { 'tags' => { 'kb' => ['https://test.com', 'http://google.com'] } }
    expect(reporter.kb_text(single)).to eq "#{Gatherlogs::Output::KB_ICON} https://test.com\n"
    expect(reporter.kb_text(array)).to eq "#{Gatherlogs::Output::KB_ICON} https://test.com\n    http://google.com\n"
  end

  it 'should return correct result message for success' do
    expect(reporter.format_result_message(success_result)).to eq '✓ CODE_DESC'
  end

  it 'should return correct result message for skipped' do
    expect(reporter.format_result_message(skipped_result)).to eq '↺ We skipped it'
  end

  it 'should return correct result message for failed' do
    expect(reporter.format_result_message(failed_result)).to eq "✗ CODE_DESC\n    Something failed"
  end

  let(:controls) do
  end

  it 'should return an ordered set of control ids' do
    expect(reporter.ordered_control_ids).to eq [[1, '000.a.b.c'], [2, '010.a.b.c'], [0, '010.d.e.f']]
  end
end
