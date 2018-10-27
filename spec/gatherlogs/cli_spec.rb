RSpec.describe Gatherlogs::CLI do
  let(:cli) do
    Gatherlogs::CLI.new({})
  end

  it "should show the inspec version" do
    allow(cli).to receive(:shellout!).with('inspec --version') { double('inspec version', stdout: '3.0') }
    expect(cli.inspec_version).to eq "inspec: 3.0"
  end

  it "should show the check_logs version" do
    Gatherlogs::VERSION = '1.0'
    expect(cli.version).to eq 'check_logs: 1.0'
  end

  it "should gather the tool versions" do
    allow(cli).to receive(:info)

    # expect(Gatherlogs).to receive(:VERSION)
    expect(cli).to receive(:version) { 'check_logs: 1.0' }
    expect(cli).to receive(:inspec_version) { 'inspec: 1.0' }
    expect(cli).to receive(:exit)

    cli.show_versions
  end

  it "should return nil if no report to print" do
    expect(cli.print_report('test', '')).to eq nil
  end
end
