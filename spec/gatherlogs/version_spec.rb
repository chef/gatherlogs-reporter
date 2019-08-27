RSpec.describe Gatherlogs::Reporter do
  it 'should show the inspec version' do
    expect(Gatherlogs::Version.inspec_version).to eq 'inspec: 4.12.0'
  end

  it 'should show the check_logs version' do
    Gatherlogs::VERSION = '1.0'.freeze
    expect(Gatherlogs::Version.cli_version).to eq 'gatherlogs_report: 1.0'
  end
end
