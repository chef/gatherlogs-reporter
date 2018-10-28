RSpec.describe Gatherlogs::CLI do
  let(:cli) do
    Gatherlogs::CLI.new({})
  end

  it "should gather the tool versions" do
    allow(cli).to receive(:info)

    # expect(Gatherlogs).to receive(:VERSION)
    expect(Gatherlogs::Version).to receive(:cli_version) { 'check_logs: 1.0' }
    expect(Gatherlogs::Version).to receive(:inspec_version) { 'inspec: 1.0' }
    # expect(cli).to receive(:exit)

    cli.show_versions
  end

  it "should call show_versions if cli flag is set" do
    expect(cli).to receive(:version?) { true }
    expect(cli).to receive(:show_versions)

    cli.execute
  end

  it "should print the profile list alphabetically" do
    cli.profiles = ['beta', 'alpha', 'gamma']
    allow(cli).to receive(:exit)

    expect{ cli.show_profiles }.to output("alpha\nbeta\ngamma\n").to_stdout
  end

  it "should call out to product.detect with the log path" do
    allow(Gatherlogs::Product).to receive(:detect).with('foo') { 'chef-server' }

    expect(cli.detect_product('foo')).to eq 'chef-server'
  end

  it "should return nil if no report to print" do
    expect(cli.print_report('test', '')).to eq nil
  end
end
