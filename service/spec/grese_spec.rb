RSpec.describe Grese do
  it 'has a version number' do
    expect(Grese::VERSION).not_to be nil
  end

  it 'shows version' do
    expect(Grese::Version.version).to match(/grese: [\d+\.]/)
  end
end
