control 'gatherlogs.automate2.elasticsearch_1gb_heap_size' do
  title 'Check that ElasticSearch is not configured with the default 1GB heap'

  desc "
ElasticSearch has been configured to use the default 1GB heap size and needs to
be updated to be at least 50% of the available memory but no more than 32GB.
"

  tag kb: 'https://automate.chef.io/docs/configuration/#setting-elasticsearch-heap'

  describe file('hab/svc/automate-elasticsearch/config/jvm.options') do
    its('content') { should_not match(/-Xms1g/) }
    its('content') { should_not match(/-Xmx1g/) }
  end
end

# Document contains at least one immense term in field
es_injest_error = log_analysis('journalctl_chef-automate.txt', 'Document contains at least one immense term in field', a2service: 'ingest-service.default')
control 'gatherlgos.automate2.immense_field_ingest_error' do
  title 'Check to see if we are running into problems ingest runs into ElasticSearch'

  desc "
ElasticSearch limits the max size for a terms in fields when saving documents.

To fix this you will need to look at the node data being captured by chef-client
and limit the size of the field being upload to the Chef-server/Automate.
"
  tag summary: es_injest_error.summary

  describe es_injest_error do
    its('last_entry') { should be_empty }
  end
end
