require 'spec_helper'

describe_inspec_resource 'common_logs' do
  context 'with defaults' do
    it 'should have solr4 files' do
      expect(resource.solr4).to eq ['current']
    end

    it 'should have erchef files' do
      expect(resource.erchef).to include('current', 'erchef.log', 'requests.log')
      expect(resource.erchef.length).to eq 13
    end

    it 'should have nginx files' do
      expect(resource.nginx).to include('current', 'access.log', 'error.log')
      expect(resource.nginx.length).to eq 4
    end

    it 'should have ss_ontap files' do
      expect(resource.ss_ontap).to include('ss_ontap.txt', 'ss.txt')
    end
  end
end
