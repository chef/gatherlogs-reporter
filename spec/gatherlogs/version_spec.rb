RSpec.describe Gatherlogs::Reporter do
  it "should show the inspec version" do
    allow(Gatherlogs::Version).to receive(:shellout!).with('inspec --version') { double('inspec version', stdout: '3.0') }
    expect(Gatherlogs::Version.inspec_version).to eq "inspec: 3.0"
  end

  it "should show the check_logs version" do
    Gatherlogs::VERSION = '1.0'
    expect(Gatherlogs::Version.cli_version).to eq 'check_logs: 1.0'
  end
end
