# level=error msg="Phase failed" error="hab-sup upgrade pending" phase="supervisor upgrade"

upgrade_failed = log_analysis('journalctl_chef-automate.txt', 'level=error msg="Phase failed" error="hab-sup upgrade pending" phase="supervisor upgrade"', a2service: 'service.default')
control 'gatherlogs.automate2.upgrade_failed' do
  impact 'critical'
  title 'Check to see if Automate is reporting a failure during the hab sup upgrade process'
  desc "
It appears that there was a failure during the upgrade process for Automate, please
check the logs and contact support to see about getting this fixed."

  tag kb: 'https://automate.chef.io/release-notes/20180706210448/#hanging-stuck-upgrades'
  tag summary: upgrade_failed.summary

  describe upgrade_failed do
    its('last_entry') { should be_empty }
  end
end

ldap_group_too_large = log_analysis('journalctl_chef-automate.txt', 'upstream sent too big header while reading response header from upstream.*dex/auth/ldap', a2service: 'automate-load-balancer.default')
control 'gatherlogs.automate2.auth_upstream_header_too_big' do
  impact 'medium'
  title 'Check to see if Automate is reporting a failure getting data from an upstream LDAP source'
  desc "
Automate is reporting errors fetching data from an upstream LDAP source. This commonly
occurs when LDAP returns too many groups or referencing LDAP groups by distinguished names (DN).

To resolve this you will need to add a `group_query_filter` to your Automate configs to
filter which groups Automate should use
  "
  tag kb: 'https://automate.chef.io/docs/ldap/#other-common-issues'
  tag summary: ldap_group_too_large.summary

  describe ldap_group_too_large do
    its('last_entry') { should be_empty }
  end
end

es_gc = log_analysis('journalctl_chef-automate.txt', '\[o.e.m.j.JvmGcMonitorService\] .* \[gc\]', a2service: 'automate-elasticsearch.default')
control 'gatherlogs.automate2.elasticsearch-high-gc-counts' do
  impact 'high'
  title 'Check to see if the ElasticSearch is reporting large number of GC events'
  desc "
The ElasticSearch service is reporting a large number of GC events, this is usually
an indication that the heap size needs to be increased.
  "

  tag kb: 'https://automate.chef.io/docs/configuration/#setting-elasticsearch-heap'
  tag summary: es_gc.summary

  describe es_gc do
    its('hits') { should cmp <= 10 }
  end
end

es_oom = log_analysis('journalctl_chef-automate.txt', 'java.lang.OutOfMemoryError', a2service: 'automate-elasticsearch.default')
control 'gatherlogs.automate2.elasticsearch_out_of_memory' do
  impact 'high'
  title 'Check to see if Automate is reporting a OutOfMemoryError for ElasticSearch'
  desc "
Automate is reporting OutOfMemoryError for ElasticSearch. Please check to heap size for ElasticSearch
and increase it if necessary or see about increasing the amount of RAM on the system.

https://automate.chef.io/docs/configuration/#setting-elasticsearch-heap
  "

  tag summary: es_oom.summary

  describe es_oom do
    its('last_entry') { should be_empty }
  end
end

# max virtual memory areas vm.max_map_count [256000] is too low, increase to at     least [262144]
es_vmc = log_analysis('journalctl_chef-automate.txt', 'max virtual memory areas vm.max_map_count \[\w+\] is too low, increase to at least \[\w+\]', a2service: 'automate-elasticsearch.default')
control 'gatherlogs.automate2.elasticsearch_max_map_count_error' do
  impact 'high'
  title 'Check to see if Automate ES is reporting a error with vm.max_map_count setting'
  desc "
ElasticSearch is reporting that the vm.max_map_count is not set correctly. This is a sysctl setting
that should be checked by the automate pre-flight tests.  If you recently rebooted make sure
the settings are set in /etc/sysctl.conf

Fix the system tuning failures indicated above by running the following:
sysctl -w vm.max_map_count=262144

To make these changes permanent, add the following to /etc/sysctl.conf:
vm.max_map_count=262144
  "

  tag summary: es_vmc.summary

  describe es_vmc do
    its('last_entry') { should be_empty }
  end
end

lb_workers = log_analysis('journalctl_chef-automate.txt', 'worker_connections are not enough', a2service: 'automate-load-balancer.default')
control 'gatherlogs.automate2.loadbalancer_worker_connections' do
  title 'Check to see if Automate is reporting a error with not enough workers for the load balancer'
  desc "
This is an issue with older version of Automate 2 without persistant connections.
Please upgrade to the latest Automate version.

If running a recent version of Automate 2 then check to make sure there are no
issues with ElasticSearch, if there are a large number of GC events or disk io
problems then the ingestion process can get backed up and cause take up all the
available workers.
  "

  tag summary: lb_workers.summary

  describe lb_workers do
    its('last_entry') { should be_empty }
  end
end

butterfly_error = log_analysis('journalctl_chef-automate.txt', 'Butterfly error: Error reading or writing to DatFile', a2service: 'hab-sup')
control 'gatherlogs.automate2.butterfly_dat_error' do
  title 'Check to see if Automate is reporting an error reading or write to a DatFile'
  desc '
  The Habitat supervisor is having problems reading or writing to an internal DatFile.

  To fix this you will need to remove the failed DatFile and restart the Automate 2 services.
  '

  tag summary: butterfly_error.summary

  describe butterfly_error do
    its('last_entry') { should be_empty }
  end
end

# FATAL:  sorry, too many clients already
pg_client_count = log_analysis('journalctl_chef-automate.txt', 'FATAL:\s+sorry, too many clients already', a2service: 'automate-postgresql.default')
control 'gatherlogs.automate2.postgresql_too_many_clients_error' do
  title 'Check to see if PostgreSQL is complaining about too many client connections'

  desc "
There appears to be too many client connections to PostgreSQL, this is a non-fatal issue
as connections should be queued.
"

  tag summary: pg_client_count.summary

  describe pg_client_count do
    its('last_entry') { should be_empty }
  end
end

panic_errors = log_analysis('journalctl_chef-automate.txt', 'panic: runtime error:')
control 'gatherlogs.automate2.panic_errors' do
  title 'Check to see if there are any panic errors in Automate logs'
  desc "
There appears to be some issue with a service throwing panic errors.  Please
check the logs for more information about what service is crashing and contact
support to in order to resolve this issue.
  "

  tag summary: panic_errors.summary
  describe panic_errors do
    its('last_entry') { should be_empty }
  end
end

certificate_permissions = log_analysis('journalctl_chef-automate.txt', 'failed to generate TLS certificate: failed to generate deployment-service TLS certificate: certstrap sign failure: Get CA certificate error: permission denied', a2service: 'deployment-service.default')
control 'gatherlogs.automate2.rootcert_permissions_error' do
  title 'Check for permission error when generating root TLS certificate'
  desc "
Automate was unable to generate a new root TLS certificate, this is needed to
create certificates used for service communication.

To fix this error you will need to manually modify the permissons in
`/hab/svc/deployment-service/data/`.

```
chmod 0440 /hab/svc/deployment-service/data/Chef_Automate*.key
chmod 0444 /hab/svc/deployment-service/data/Chef_Automate*.crt /hab/svc/deployment-service/data/Chef_Automate*.crl
```
  "

  tag summary: certificate_permissions.summary
  describe certificate_permissions do
    its('last_entry') { should be_empty }
  end
end

saml_audience_check = log_analysis('journalctl_chef-automate.txt', 'Failed to authenticate: required audience', a2service: 'automate-dex.default')
control 'gatherlogs.automate2.failed_saml_audience_response' do
  title 'Check for errors related to failed audience checks for SAML IdP responses'
  desc "
Automate was unable to validate the SAML assertion for `AudienceRestriction` contained a valid value.

Possible ways to fix this:
1. Ensure that the response from the SAML IdP contains `https://AUTOMATE_HOST/dex/callback` in the response XML
2. Disable `AudienceRestriction` on the SAML IdP
3. Set `entity_issuer` in `[dex.v1.sys.connectors.saml]` to the value it should match (https://automate.chef.io/docs/configuration/#saml)
  "

  tag kb: 'https://automate.chef.io/docs/configuration/#saml'

  tag summary: saml_audience_check.summary
  describe saml_audience_check do
    its('last_entry') { should be_empty }
  end
end
