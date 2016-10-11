
# YARN Timeline Server Configure

```json
{ "ryba": { "yarn": { "ats": {
  "opts": "",
  "heapsize": "1024"
} } } }
```

    module.exports = ->
      # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.0/bk_yarn_resource_mgt/content/ref-c2f35f55-fa15-4154-b80a-36df2db297d5.1.html
      {yarn, core_site, realm} = @config.ryba
      yarn.ats ?= {}
      yarn.ats.log_dir ?= '/var/log/hadoop-yarn'
      yarn.ats.pid_dir ?= '/var/run/hadoop-yarn'
      yarn.ats.conf_dir ?= '/etc/hadoop-yarn-timelineserver/conf'
      yarn.ats.opts ?= ''
      yarn.ats.heapsize ?= '1024'
      # The hostname of the Timeline service web application.
      yarn.site['yarn.timeline-service.hostname'] ?= @config.host
      hostname = yarn.site['yarn.timeline-service.hostname']
      yarn.site['yarn.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      # Advanced Configuration
      yarn.site['yarn.timeline-service.address'] ?= "#{hostname}:10200"
      yarn.site['yarn.timeline-service.webapp.address'] ?= "#{hostname}:8188"
      yarn.site['yarn.timeline-service.webapp.https.address'] ?= "#{hostname}:8190"
      yarn.site['yarn.timeline-service.handler-thread-count'] ?= "100" # HDP default is "10"
      yarn.site['yarn.timeline-service.http-cross-origin.enabled'] ?= "true"
      yarn.site['yarn.timeline-service.http-cross-origin.allowed-origins'] ?= "*"
      yarn.site['yarn.timeline-service.http-cross-origin.allowed-methods'] ?= "GET,POST,HEAD"
      yarn.site['yarn.timeline-service.http-cross-origin.allowed-headers'] ?= "X-Requested-With,Content-Type,Accept,Origin"
      yarn.site['yarn.timeline-service.http-cross-origin.max-age'] ?= "1800"
      # Generic-data related Configuration
      # Yarn doc: yarn.timeline-service.generic-application-history.enabled = false
      yarn.site['yarn.timeline-service.generic-application-history.store-class'] ?= "org.apache.hadoop.yarn.server.applicationhistoryservice.FileSystemApplicationHistoryStore"
      yarn.site['yarn.timeline-service.fs-history-store.uri'] ?= '/apps/ats' # Not documented, default to "$(hadoop.tmp.dir)/yarn/timeline/generic-history""
      # Enabling Generic Data Collection (HDP specific)
      yarn.site['yarn.resourcemanager.system-metrics-publisher.enabled'] ?= "true"
      # Per-framework-date related Configuration
      # Indicates to clients whether or not the Timeline Server is enabled. If
      # it is enabled, the TimelineClient library used by end-users will post
      # entities and events to the Timeline Server.
      yarn.site['yarn.timeline-service.enabled'] ?= "true"
      # Timeline Server Store
      yarn.site['yarn.timeline-service.store-class'] ?= "org.apache.hadoop.yarn.server.timeline.LeveldbTimelineStore"
      yarn.site['yarn.timeline-service.leveldb-timeline-store.path'] ?= "/var/yarn/timeline"
      yarn.site['yarn.timeline-service.ttl-enable'] ?= "true"
      yarn.site['yarn.timeline-service.ttl-ms'] ?= "#{604800000 * 2}" # 14 days, HDP default is "604800000"
      # Kerberos Authentication
      yarn.site['yarn.timeline-service.principal'] ?= "ats/_HOST@#{realm}"
      yarn.site['yarn.timeline-service.keytab'] ?= '/etc/security/keytabs/ats.service.keytab'
      yarn.site['yarn.timeline-service.http-authentication.type'] ?= "kerberos"
      yarn.site['yarn.timeline-service.http-authentication.kerberos.principal'] ?= "HTTP/_HOST@#{realm}"
      yarn.site['yarn.timeline-service.http-authentication.kerberos.keytab'] ?= core_site['hadoop.http.authentication.kerberos.keytab']
      # Timeline Server Authorization (ACLs)
      yarn.site['yarn.acl.enable'] ?= "true"
      # yarn.site['yarn.admin.acl'] ?= "#{yarn.user.name}"
       # List of users separated by commas
      # SSL, must be added to "core-site.xml"
      # yarn.site['hadoop.ssl.require.client.cert'] ?= "false"
      # yarn.site['hadoop.ssl.hostname.verifier'] ?= "DEFAULT"
      # yarn.site['hadoop.ssl.keystores.factory.class'] ?= "org.apache.hadoop.security.ssl.FileBasedKeyStoresFactory"
      # yarn.site['hadoop.ssl.server.conf'] ?= "ssl-server.xml"
      # yarn.site['hadoop.ssl.client.conf'] ?= "ssl-client.xml"
