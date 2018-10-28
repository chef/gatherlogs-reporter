class ShelloutTest
  include Gatherlogs::Shellout
end

RSpec.describe Gatherlogs::Shellout do
  let(:shellout) do
    ShelloutTest.new
  end

  it "should call out to mixlib shellout!" do
    dbl = double('cmd')
    allow(Mixlib::ShellOut).to receive(:new).with('test', {}) { dbl }
    allow(dbl).to receive(:run_command)
    allow(dbl).to receive(:error!)

    expect(shellout.shellout!('test')).to eq dbl
  end
end
