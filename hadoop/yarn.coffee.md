
# YARN

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push '!masson/bootstrap/info'
    module.exports.push 'ryba/hadoop/core'

    module.exports.push module.exports.configure = (ctx) ->
      return if ctx.yarn_configured
      ctx.yarn_configured = true
      require('masson/commons/java').configure ctx
      require('./hdfs').configure ctx
      {ryba} = ctx.config
      {static_host, realm} = ryba
      # Grab the host(s) for each roles
      ryba.yarn.log_dir ?= '/var/log/hadoop-yarn'         # /etc/hadoop/conf/yarn-env.sh#20
      ryba.yarn.pid_dir ?= '/var/run/hadoop-yarn'         # /etc/hadoop/conf/yarn-env.sh#21
      # Configure yarn
      ryba.yarn.site['yarn.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      # NodeManager Memory (should move to yarn_nm but we need to implement memory differently)
      ryba.yarn.site['yarn.nodemanager.local-dirs'] ?= ['/var/yarn/local']
      ryba.yarn.site['yarn.nodemanager.local-dirs'] = ryba.yarn.site['yarn.nodemanager.local-dirs'].join ',' if Array.isArray ryba.yarn.site['yarn.nodemanager.local-dirs']
      ryba.yarn.site['yarn.nodemanager.log-dirs'] ?= ['/var/yarn/logs']
      ryba.yarn.site['yarn.nodemanager.log-dirs'] = ryba.yarn.site['yarn.nodemanager.log-dirs'].join ',' if Array.isArray ryba.yarn.site['yarn.nodemanager.log-dirs']
      # Required by yarn client
      ryba.yarn.site['yarn.resourcemanager.principal'] ?= "rm/#{static_host}@#{realm}"
      # Configurations for History Server (Needs to be moved elsewhere):
      ryba.yarn.site['yarn.log-aggregation.retain-seconds'] ?= '-1' #  How long to keep aggregation logs before deleting them. -1 disables. Be careful, set this too small and you will spam the name node.
      ryba.yarn.site['yarn.log-aggregation.retain-check-interval-seconds'] ?= '-1' # Time between checks for aggregated log retention. If set to 0 or a negative value then the value is computed as one-tenth of the aggregated log retention time. Be careful, set this too small and you will spam the name node.
      [jhs_context] = ctx.contexts 'ryba/hadoop/mapred_jhs', require('./mapred_jhs').configure
      if jhs_context
        # TODO: detect https and port, see "./mapred_jhs_check"
        jhs_protocol = if jhs_context.config.ryba.mapred.site['mapreduce.jobhistory.address'] is 'HTTP_ONLY' then 'http' else 'https'
        jhs_protocol_key = if jhs_protocol is 'http' then '' else '.https'
        jhs_address = jhs_context.config.ryba.mapred.site["mapreduce.jobhistory.webapp#{jhs_protocol_key}.address"]
        ryba.yarn.site['yarn.log.server.url'] ?= "#{jhs_protocol}://#{jhs_address}/jobhistory/logs/"

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

## Configuration for Resource Allocation


http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.3.1/bk_installing_manually_book/content/rpm-chap1-9.html
http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html#Running_Hadoop_in_Secure_Mode

    module.exports.push name: 'YARN # Users & Groups', handler: (ctx, next) ->
      return next() unless ctx.config.ryba.resourcemanager or ctx.config.ryba.nodemanager
      {yarn, hadoop_group} = ctx.config.ryba
      ctx.execute
        cmd: "useradd #{yarn.user.name} -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Hadoop YARN service\""
        code: 0
        code_skipped: 9
      , next

    module.exports.push name: 'YARN # Install Common', timeout: -1, handler: (ctx, next) ->
      ctx.service [
        name: 'hadoop'
      ,
        name: 'hadoop-yarn'
      ,
        name: 'hadoop-client'
      ], next

    module.exports.push name: 'YARN # Directories', timeout: -1, handler: (ctx, next) ->
      {yarn, hadoop_group} = ctx.config.ryba
      ctx.mkdir
        destination: "#{yarn.log_dir}/#{yarn.user.name}"
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o0755
      ,
        destination: "#{yarn.pid_dir}/#{yarn.user.name}"
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o0755
      , next

    module.exports.push name: 'YARN # Yarn OPTS', handler: (ctx, next) ->
      {java_home} = ctx.config.java
      {yarn, hadoop_group, hadoop_conf_dir} = ctx.config.ryba
      yarn_opts = ""
      for k, v of ctx.config.ryba.yarn.opts
        yarn_opts += "-D#{k}=#{v} "
      yarn_opts = "YARN_OPTS=\"$YARN_OPTS #{yarn_opts}\" # ryba"
      ctx.config.ryba.yarn.opts = yarn_opts
      ctx.render
        source: "#{__dirname}/../resources/core_hadoop/yarn-env.sh"
        destination: "#{hadoop_conf_dir}/yarn-env.sh"
        local_source: true
        write: [
          match: /^export JAVA_HOME=.*$/mg
          replace: "export JAVA_HOME=#{java_home}"
        ,
          match: /^.*ryba$/mg
          replace: yarn_opts
          append: 'yarn.policy.file'
        ]
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o0755
      , next

    module.exports.push name: 'YARN # Configuration', handler: (ctx, next) ->
      {yarn, hadoop_conf_dir} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/yarn-site.xml"
        default: "#{__dirname}/../resources/core_hadoop/yarn-site.xml"
        local_default: true
        properties: yarn.site
        merge: true
        backup: true
      , next

[cloudera_ha]: http://www.cloudera.com/content/cloudera/en/documentation/cdh5/v5-1-x/CDH5-High-Availability-Guide/cdh5hag_rm_ha_config.html









