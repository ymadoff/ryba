
# YARN Client

The [Hadoop YARN Client](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/WebServicesIntro.html) web service REST APIs are a set of URI resources that give access to the cluster, nodes, applications, and application historical information.
The URI resources are grouped into APIs based on the type of information returned. Some URI resources return collections while others return singletons.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push '!masson/bootstrap/info'
    module.exports.push 'ryba/hadoop/core'

## Configuration

    module.exports.push module.exports.configure = (ctx) ->
      return if ctx.yarn_configured
      ctx.yarn_configured = true
      require('masson/commons/java').configure ctx
      require('../hdfs_client').configure ctx
      {ryba} = ctx.config
      {static_host, realm} = ryba
      # Grab the host(s) for each roles
      ryba.yarn.log_dir ?= '/var/log/hadoop-yarn'         # /etc/hadoop/conf/yarn-env.sh
      ryba.yarn.pid_dir ?= '/var/run/hadoop-yarn'
      ryba.yarn.conf_dir ?= ryba.hadoop_conf_dir
      ryba.yarn.opts ?= ''
      # Configure yarn
      ryba.yarn.site['yarn.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      # Required by yarn client
      ryba.yarn.site['yarn.resourcemanager.principal'] ?= "rm/#{static_host}@#{realm}"
      # Configurations for History Server (Needs to be moved elsewhere):
      ryba.yarn.site['yarn.log-aggregation.retain-seconds'] ?= '-1' #  How long to keep aggregation logs before deleting them. -1 disables. Be careful, set this too small and you will spam the name node.
      ryba.yarn.site['yarn.log-aggregation.retain-check-interval-seconds'] ?= '-1' # Time between checks for aggregated log retention. If set to 0 or a negative value then the value is computed as one-tenth of the aggregated log retention time. Be careful, set this too small and you will spam the name node.
      # Fix yarn application classpath, some application like the distributed shell
      # wont replace "hdp.version" and result in class not found.
      # ryba.yarn.site['yarn.application.classpath'] ?= "$HADOOP_CONF_DIR,/usr/hdp/${hdp.version}/hadoop-client/*,/usr/hdp/${hdp.version}/hadoop-client/lib/*,/usr/hdp/${hdp.version}/hadoop-hdfs-client/*,/usr/hdp/${hdp.version}/hadoop-hdfs-client/lib/*,/usr/hdp/${hdp.version}/hadoop-yarn-client/*,/usr/hdp/${hdp.version}/hadoop-yarn-client/lib/*"
      ryba.yarn.site['yarn.application.classpath'] ?= "$HADOOP_CONF_DIR,/usr/hdp/current/hadoop-client/*,/usr/hdp/current/hadoop-client/lib/*,/usr/hdp/current/hadoop-hdfs-client/*,/usr/hdp/current/hadoop-hdfs-client/lib/*,/usr/hdp/current/hadoop-yarn-client/*,/usr/hdp/current/hadoop-yarn-client/lib/*"
      [jhs_context] = ctx.contexts 'ryba/hadoop/mapred_jhs', require('../mapred_jhs').configure
      if jhs_context
        # TODO: detect https and port, see "../mapred_jhs/check"
        jhs_protocol = if jhs_context.config.ryba.mapred.site['mapreduce.jobhistory.address'] is 'HTTP_ONLY' then 'http' else 'https'
        jhs_protocol_key = if jhs_protocol is 'http' then '' else '.https'
        jhs_address = jhs_context.config.ryba.mapred.site["mapreduce.jobhistory.webapp#{jhs_protocol_key}.address"]
        ryba.yarn.site['yarn.log.server.url'] ?= "#{jhs_protocol}://#{jhs_address}/jobhistory/logs/"
      # Yarn Timeline Server
      [ts_ctx] = ctx.contexts 'ryba/hadoop/yarn_ts', require('../yarn_ts').configure
      ts_properties = [
        'yarn.timeline-service.enabled'
        'yarn.timeline-service.address'
        'yarn.timeline-service.webapp.address'
        'yarn.timeline-service.webapp.https.address'
        'yarn.timeline-service.principal'
        'yarn.timeline-service.http-authentication.type'
        'yarn.timeline-service.http-authentication.kerberos.principal'
      ]
      for property in ts_properties
        ryba.yarn.site[property] ?= if ts_ctx then ts_ctx.config.ryba.yarn.site[property] else null

## Configuration for High Availability

Cloudera [High Availability Guide][cloudera_ha] provides a nice documentation
about each configuration and where they should apply.

Unless specified otherwise, the active ResourceManager is the first one defined
inside the configuration.

      rm_ctxs = ctx.contexts modules: 'ryba/hadoop/yarn_rm'
      rm_shortnames = for rm_ctx in rm_ctxs then rm_ctx.config.shortname
      is_ha = rm_ctxs.length > 1
      ryba.yarn.active_rm_host ?= if is_ha then rm_ctxs[0].config.host else null
      if ctx.has_any_modules 'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm', 'ryba/hadoop/yarn_client'
        ryba.yarn.site['yarn.resourcemanager.ha.enabled'] ?= if is_ha then 'true' else 'false'
        ryba.yarn.site['yarn.resourcemanager.ha.rm-ids'] ?= rm_shortnames.join ',' if is_ha
        # Flag to enable override of the default kerberos authentication
        # filter with the RM authentication filter to allow authentication using
        # delegation tokens(fallback to kerberos if the tokens are missing)
        ryba.yarn.site["yarn.resourcemanager.webapp.delegation-token-auth-filter.enabled"] ?= "true" # YARN default is "true"
      if ctx.has_module 'ryba/hadoop/yarn_rm'
        ryba.yarn.site['yarn.resourcemanager.ha.id'] ?= ctx.config.shortname if is_ha
      for rm_ctx in rm_ctxs
        shortname = if is_ha then ".#{rm_ctx.config.shortname}" else ''
        if ctx.has_any_modules 'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_client'
          ryba.yarn.site["yarn.resourcemanager.address#{shortname}"] ?= "#{rm_ctx.config.host}:8050"
          ryba.yarn.site["yarn.resourcemanager.scheduler.address#{shortname}"] ?= "#{rm_ctx.config.host}:8030"
          ryba.yarn.site["yarn.resourcemanager.admin.address#{shortname}"] ?= "#{rm_ctx.config.host}:8141"
          ryba.yarn.site["yarn.resourcemanager.webapp.address#{shortname}"] ?= "#{rm_ctx.config.host}:8088"
          ryba.yarn.site["yarn.resourcemanager.webapp.https.address#{shortname}"] ?= "#{rm_ctx.config.host}:8090"
        if ctx.has_any_modules 'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm'
          ryba.yarn.site["yarn.resourcemanager.resource-tracker.address#{shortname}"] ?= "#{rm_ctx.config.host}:8025"

## FIX Companion Files

The "yarn-site.xml" file provided inside the companion files set some some
values that shall be overwritten by the user. This middleware ensures those
values don't get pushed to the cluster.

      unless ctx.has_any_modules 'ryba/hadoop/yarn_rm'
        ryba.yarn.site['yarn.scheduler.minimum-allocation-mb'] ?= null # Make sure we erase hdp default value
        ryba.yarn.site['yarn.scheduler.maximum-allocation-mb'] ?= null # Make sure we erase hdp default value

## Commands

    module.exports.push commands: 'check', modules: 'ryba/hadoop/yarn_client/check'

    module.exports.push commands: 'report', modules: 'ryba/hadoop/yarn_client/report'

    module.exports.push commands: 'install', modules: [
      'ryba/hadoop/yarn_client/install'
      'ryba/hadoop/yarn_client/check'
    ]

[cloudera_ha]: http://www.cloudera.com/content/cloudera/en/documentation/cdh5/v5-1-x/CDH5-High-Availability-Guide/cdh5hag_rm_ha_config.html
