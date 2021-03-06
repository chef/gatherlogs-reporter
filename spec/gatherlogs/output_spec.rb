class TestOutput
  include Gatherlogs::Output
  def initialize
    enable_colors
  end
end

RSpec.describe Gatherlogs::Output do
  let(:test_output) do
    TestOutput.new
  end

  let(:logger_dbl) do
    double('Logger')
  end

  let(:green) do
    '#32CD32'
  end

  context :logger do
    before do
      Gatherlogs.logger = logger_dbl
    end

    it 'should print plain log output' do
      test_output.disable_colors
      allow(logger_dbl).to receive(:info).with('info')
      allow(logger_dbl).to receive(:debug).with('debug')
      allow(logger_dbl).to receive(:error).with('err')

      test_output.info('info', green)
      test_output.debug('debug', green)
      test_output.error('err', green)
    end

    it 'should print colored log output' do
      allow(logger_dbl).to receive(:info).with("\e[38;2;50;205;50minfo\e[0m")
      allow(logger_dbl).to receive(:debug).with("\e[38;2;50;205;50mdebug\e[0m")
      allow(logger_dbl).to receive(:error).with("\e[38;2;50;205;50merr\e[0m")

      test_output.info('info', green)
      test_output.debug('debug', green)
      test_output.error('err', green)
    end

    it 'should auto set colors for logged output' do
      allow(logger_dbl).to receive(:info).with("\e[38;2;50;205;50minfo\e[0m")
      allow(logger_dbl).to receive(:debug).with("\e[38;2;255;140;0mdebug\e[0m")
      allow(logger_dbl).to receive(:error).with("\e[38;2;255;51;51merr\e[0m")

      test_output.info('info')
      test_output.debug('debug')
      test_output.error('err')
    end
  end

  it 'should colorize the text' do
    expect(test_output.colorize('test', green)).to eq "\e[38;2;50;205;50mtest\e[0m"
  end

  it 'should not colorize the text' do
    test_output.disable_colors
    expect(test_output.colorize('test', green)).to eq 'test'
  end

  it 'should default to returning text with 4 spaces' do
    expect(test_output.tabbed_text("123\nabc\n")).to eq "123\n    abc"
  end

  it 'should add additional spaces' do
    expect(test_output.tabbed_text("123\nabc", 2)).to eq "123\n      abc"
  end

  it 'should return text with labels' do
    test_output.disable_colors
    expect(test_output.labeled_output('✓', '123')).to eq '✓ 123'
  end

  it 'should return nil if nil is given' do
    expect(test_output.subsection(nil)).to eq nil
  end

  it 'should space subsection output' do
    expect(test_output.subsection('test out')).to eq '  test out'
  end

  it 'should return truncate output' do
    expect(test_output.truncate('-' * 800)).to eq '-' * 700
    expect(test_output.truncate('-' * 800, 5)).to eq '-----'
  end
end
