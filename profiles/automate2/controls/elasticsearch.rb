control 'gatherlogs.automate2.elasticsearch_1gb_heap_size' do
  title 'Check that ElasticSearch is not configured with the default 1GB heap'
  impact 'critical'

  desc "
ElasticSearch has been configured to use the default 1GB heap size and needs to
be updated to be at least 25% of the available memory but no more than 50% or
26GB.
"

  tag kb: 'https://automate.chef.io/docs/configuration/#setting-elasticsearch-heap'

  describe file('hab/svc/automate-elasticsearch/config/jvm.options') do
    its('content') { should_not match(/-Xms1g/) }
    its('content') { should_not match(/-Xmx1g/) }
  end
end

# Document contains at least one immense term in field
es_injest_error = log_analysis('journalctl_chef-automate.txt', 'Document contains at least one immense term in field', a2service: 'ingest-service.default')
control 'gatherlogs.automate2.immense_field_ingest_error' do
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

es_translog_truncated = log_analysis('journalctl_chef-automate.txt', 'misplaced codec footer \(file truncated\?\)', a2service: 'automate-elasticsearch.default')
control 'gatherlogs.automate2.elasticsearch_translog_truncated' do
  title 'Check to see if there are any errors about truncated transaction logs'
  desc "
Elasticsearch is reporting errors for possibly truncated or corrupted transaction
logs.  This can happen if there was a disk full event that occured or if the ES
service was unexpectedly terminated.

To resolve this:
1. Stop Automate services
2. Remove the bad transaction log file
3. Start the services again.
  "

  tag kb: [
    'https://www.elastic.co/guide/en/elasticsearch/reference/current/index-modules-translog.html#corrupt-translog-truncation'
  ]

  tag summary: es_translog_truncated.summary
  describe es_translog_truncated do
    its('last_entry') { should be_empty }
  end
end

es_insufficient_memory = log_analysis('journalctl_chef-automate.txt', 'There is insufficient memory for the Java Runtime Environment to continue', a2service: 'automate-elasticsearch')
control 'gatherlogs.automate2.elasticsearch_insufficent_memory' do
  title 'Check to see if ElasticSearch has issues starting up due to memory issues'
  desc "
Java is reporting insufficient memory while trying to start ElasticSearch. Check
to make sure that the configured Heap size is not too large or that there is
enough free memory to allocate the assigned heap space. ElasticSearch java heap
should be configured with least 25% of the available memory but no more than 50%
or 26GB.

Also check that there are no other processing using a large amount of memory.
  "

  tag summary: es_insufficient_memory.summary
  describe es_insufficient_memory do
    its('last_entry') { should be_empty }
  end
end

# primary shard is not active
primary_shard = log_analysis('journalctl_chef-automate.txt', 'primary shard is not active', a2service: 'automate-elasticsearch')
control 'gatherlogs.automate2.elasticsearch_primary_shard_unavailable' do
  title 'Check to see if Elasticsearch is reporting issues with primary shards'
  desc "
Elasticsearch is reporting that there are primary shards that are unavailable.

To attempt a retry for the shards, issue the following

    curl -XPOST 'localhost:10144/_cluster/reroute?retry_failed&pretty'

If that gives an error saying the shard is already assigned, then you will need to issue a flush to clear
the sync ID per each associated index that you received the 'already assigned' error for, and then retry
the above reroute command

    curl -XPOST 'localhost:10144/INDEX_NAME/_flush?force=true&pretty'
  "

  tag summary: primary_shard.summary
  describe primary_shard do
    its('last_entry') { should be_empty }
  end
end

# read-only indices
read_only = log_analysis('elasticsearch_cluster_state.txt', '"read_only_allow_delete"\s+:\s+"true"')
control 'gatherlogs.automate2.elasticsearch_read_only_indicies' do
  title 'Check to see if ElasticSearch is reporting any indicies as read_only'
  desc "
  ElasticSearch is reporting that some indices are read-only. Typically this
  happens when the disk that contains the ElasticSearch database runs low on
  available free space.

  It's possible that this can be triggered when running a backup if `/hab` and
  the local backup directory are on the same mount. For example if `/hab` is
  symlinked to `/var/chef-automate` or a similar location in `/var`, then if the
  backup uses a large amount of disk space and then later cleans it up this
  could trigger a low disk warning in ES and cause it to mark the indices as
  read-only. Then later, the system appears to have adequate free space.

  Once the disk space issues are resolved, you can remove the read-only flag by
  running the following command from the Automate server:
    curl -k -XPUT -H \"Content-Type: application/json\" http://localhost:10144/_all/_settings -d '{\"index.blocks.read_only_allow_delete\": null}'
  "

  tag summary: read_only.summary
  describe read_only do
    its('last_entry') { should be_empty }
  end
end
