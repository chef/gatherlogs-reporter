RSpec.describe Gatherlogs::Reporter do
  it 'should show the inspec version' do
    expect(Gatherlogs::Version.inspec_version).to eq 'inspec-core: 4.18.0'
  end

  it 'should show the check_logs version' do
    Gatherlogs::VERSION = '1.0'.freeze
    expect(Gatherlogs::Version.cli_version).to eq 'gatherlog: 1.0'
  end

  it 'should gather the tool versions' do
    expect(Gatherlogs::Version).to receive(:cli_version) { 'gatherlog: 1.0' }
    expect(Gatherlogs::Version).to receive(:inspec_version) { 'inspec-core: 1.0' }

    expect { Gatherlogs::Version.show }.to output("gatherlog: 1.0\ninspec-core: 1.0\n").to_stdout
  end
end
