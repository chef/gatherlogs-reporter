require 'spec_helper'

describe_inspec_resource 'cpu_info' do
  context 'with bad content' do
    before do
      environment do
        file('cpuinfo.txt').returns(exist?: true, content: 'foo')
      end
    end

    it 'should exist' do
      expect(resource.exists?).to eq(true)
    end

    it 'should have content' do
      expect(resource.read_content).to eq ['foo']
    end

    it 'should have unknown model' do
      expect(resource.model_name).to eq 'Unknown'
    end

    it 'should have no cpus' do
      expect(resource.cpus).to eq []
    end

    it 'should return 0 cpu count' do
      expect(resource.total).to eq 0
    end
  end


  context 'with cpuinfo.txt' do
    before do
      environment do
        file('cpuinfo.txt').returns(exist?: true, content: File.read('spec/fixtures/cpuinfo.txt'))
      end
    end

    it 'should exist' do
      expect(resource.exists?).to eq(true)
    end

    it 'should have content' do
      expect(resource.read_content.length).to eq 208
    end

    it 'should have unknown model' do
      expect(resource.model_name).to eq 'Intel(R) Xeon(R) CPU E7-8890 v4 @ 2.20GHz'
    end

    it 'should have some cpus' do
      expect(resource.cpus.length).to eq 8
    end

    it 'should have 8 cpus' do
      expect(resource.total).to eq 8
    end
  end

  context 'with proc/cpuinfo' do
    it 'should exist' do
      environment do
        file('cpuinfo.txt').returns(exist?: false)
        file('proc/cpuinfo').returns(exist?: true, content: 'foo')
      end

      expect(resource.exists?).to eq(true)
    end
  end

  context 'with no file' do
    it 'should not exist' do
      environment do
        file('cpuinfo.txt').returns(exist?: false)
        file('proc/cpuinfo').returns(exist?: false)
        file('invalid').returns(exist?: false)
      end

      expect(resource.exists?).to eq(false)
    end
  end
end
