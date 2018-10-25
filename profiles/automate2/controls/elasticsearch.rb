control 'gatherlogs.automate2.elasticsearch_1gb_heap_size' do
  title 'Check that ElasticSearch is not configured with the default 1GB heap'

  desc "
ElasticSearch has been configured to use the default 1GB heap size and needs to
be updated to be at least 50% of the available memory but no more than 32GB.
"

  tag kb: "https://automate.chef.io/docs/configuration/#setting-elasticsearch-heap"

  describe file('hab/svc/automate-elasticsearch/config/jvm.options') do
    its('content') { should_not match(/-Xms1g/) }
    its('content') { should_not match(/-Xmx1g/) }
  end
end
