RSpec.describe Gatherlogs::Profiles do
  it 'should find a list of profiles' do
    allow(Dir).to receive(:glob).with(File.expand_path('profiles/*/inspec.yml')) {
      [
        'profiles/beta/inspec.yml', 'profiles/alpha/inspec.yml',
        'profiles/gamma/inspec.yml', 'profiles/common/inspec.yml',
        'profiles/glresources/inspec.yml'
      ]
    }

    expect(Gatherlogs::Profiles.find).to eq %w[beta alpha gamma common glresources]
  end

  it 'should print the profile list alphabetically' do
    # Gatherlogs::Profiles.profiles = %w[beta alpha gamma common glresources]
    allow(Gatherlogs::Profiles).to receive(:find) { %w[beta alpha gamma common glresources] }

    expect(Gatherlogs::Profiles.list).to eq %w[alpha beta gamma]
  end
end
