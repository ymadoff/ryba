
# YARN Timeline Server

The [Yarn Timeline Server][ts] store and retrieve current as well as historic
information for the applications running inside YARN.

    module.exports = []

    module.exports.configure = (ctx) ->
      # require('../core').configure ctx
      require('../yarn_client').configure ctx
      {yarn, core_site, realm} = ctx.config.ryba
      # The hostname of the Timeline service web application.
      yarn.site['yarn.timeline-service.hostname'] ?= ctx.config.host
      hostname = yarn.site['yarn.timeline-service.hostname']
      # Advanced Configuration
      yarn.site['yarn.timeline-service.address'] ?= "#{hostname}:10200"
      yarn.site['yarn.timeline-service.webapp.address'] ?= "#{hostname}:8188"
      yarn.site['yarn.timeline-service.webapp.https.address'] ?= "#{hostname}:8190"
      yarn.site['yarn.timeline-service.handler-thread-count'] ?= "10"
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
      yarn.site['yarn.timeline-service.ttl-ms'] ?= "#{604800000 * 2}" # 14 days
      # Kerberos Authentication
      yarn.site['yarn.timeline-service.principal'] ?= "ats/_HOST@#{realm}"
      yarn.site['yarn.timeline-service.keytab'] ?= '/etc/security/keytabs/ats.service.keytab'
      yarn.site['yarn.timeline-service.http-authentication.type'] ?= "kerberos"
      yarn.site['yarn.timeline-service.http-authentication.kerberos.principal'] ?= "HTTP/_HOST@#{realm}"
      yarn.site['yarn.timeline-service.http-authentication.kerberos.keytab'] ?= core_site['hadoop.http.authentication.kerberos.keytab']
      # Timeline Server Authorization (ACLs)
      yarn.site['yarn.acl.enable'] ?= "true"
      yarn.site['yarn.admin.acl'] ?= ""


    module.exports.push commands: 'check', modules: 'ryba/hadoop/yarn_ts/check'

    module.exports.push commands: 'install', modules: [
      'ryba/hadoop/yarn_ts/install'
      'ryba/hadoop/yarn_ts/start'
      'ryba/hadoop/yarn_ts/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/hadoop/yarn_ts/start'

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/yarn_ts/stop'

[ts]: http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/TimelineServer.html
