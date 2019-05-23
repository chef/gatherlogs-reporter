require 'spec_helper'

describe_inspec_resource 'disk_usage' do
  context 'with bad content' do
    before do
      environment do
        file('df_h.txt').returns(exist?: false, content: '')
      end
    end

    it 'should not find root fs' do
      expect(resource.exists?('/')).to eq false
    end

    it 'should not return a mount' do
      expect(resource.mount('/').exists?).to eq false
    end
  end

  context 'with good content' do
    before do
      environment do
        file('df_h.txt').returns(exist?: true, content: File.read('spec/fixtures/df_h.txt'))
      end
    end

    let(:rootfs) { resource.mount('/') }
    let(:nofs) { resource.mount('nofs') }

    it 'should find root fs' do
      expect(rootfs.exists?).to eq true
    end

    it 'should not find non-existant fs' do
      expect(nofs.exists?).to eq false
    end

    it 'should not return size for non-existant fs' do
      expect(nofs.size).to eq nil
    end

    it 'should return a mount' do
      expect(rootfs).to_not eq nil
    end

    it 'should have a size' do
      expect(rootfs.size).to eq "10035.2M"
    end
  end
end
