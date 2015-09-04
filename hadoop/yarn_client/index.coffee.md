
# YARN Client

The [Hadoop YARN Client](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/WebServicesIntro.html) web service REST APIs are a set of URI resources that give access to the cluster, nodes, applications, and application historical information.
The URI resources are grouped into APIs based on the type of information returned. Some URI resources return collections while others return singletons.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push '!masson/bootstrap/info'
    module.exports.push 'ryba/hadoop/core'

## Configuration

    module.exports.configure = (ctx) ->
      return if ctx.yarn_configured
      ctx.yarn_configured = true
      require('masson/commons/java').configure ctx
      require('../hdfs_client').configure ctx
      {ryba} = ctx.config
      {static_host, realm} = ryba
      # Grab the host(s) for each roles
      ryba.yarn.log_dir ?= '/var/log/hadoop-yarn'
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
      [ats_ctx] = ctx.contexts 'ryba/hadoop/yarn_ts', require('../yarn_ts').configure
      ats_properties = [
        'yarn.timeline-service.enabled'
        'yarn.timeline-service.address'
        'yarn.timeline-service.webapp.address'
        'yarn.timeline-service.webapp.https.address'
        'yarn.timeline-service.principal'
        'yarn.timeline-service.http-authentication.type'
        'yarn.timeline-service.http-authentication.kerberos.principal'
      ]
      for property in ats_properties
        ryba.yarn.site[property] ?= if ats_ctx then ats_ctx.config.ryba.yarn.site[property] else null

## High Availability with Manual Failover

Cloudera [High Availability Guide][cloudera_ha] provides a nice documentation
about each configuration and where they should apply.

Unless specified otherwise, the active ResourceManager is the first one defined
inside the configuration.

      rm_ctxs = ctx.contexts modules: 'ryba/hadoop/yarn_rm'
      rm_shortnames = for rm_ctx in rm_ctxs then rm_ctx.config.shortname
      is_ha = rm_ctxs.length > 1
      ryba.yarn.site['yarn.resourcemanager.cluster-id'] ?= 'yarn_cluster_01'
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

## High Availability with optional automatic failover

      ryba.yarn.site['yarn.resourcemanager.ha.automatic-failover.enabled'] ?= 'true'
      ryba.yarn.site['yarn.resourcemanager.ha.automatic-failover.embedded'] ?= 'true'
      # ryba.yarn.site['yarn.resourcemanager.cluster-id'] ?= 'yarn_cluster_01'

## Work Preserving Recovery

Work Preserving Recovery is a feature that enhances ResourceManager to
keep functioning across restarts and also makes ResourceManager down-time
invisible to end-users.

[Phase1][YARN-556-pdf] covered by [YARN-128] allowed YARN to continue to
function across RM restarts in a user transparent manner. [Phase2][YARN-556-pdf]
covered by [YARN-556] refresh the dynamic container state of the cluster from
the node managers (NMs) after RM restart such as restarting AM’s and killing
containers is not required.

Restart Recovery apply separately to both the ResourceManager and NodeManager.
The functionnality is supported by [Cloudera][cloudera_wp] and [Hortonworks][hdp_wp].

HDP companion files enable by default the recovery mode. Its implementation
default to the ZooKeeper based state-store implementation. Unless specified,
the root znode where the ResourceManager state is stored is inside "/rmstore".

ZooKeeper is used in the context of restart recovering and high availability.

About the 'root-node.acl', the [mailing list][ml_root_acl] mentions: For the
exclusive create-delete access, the RMs use username:password where the username
is yarn.resourcemanager.address and the password is a secure random number. One
should use that config only when they are not happy with this implicit default
mechanism.

Here's an example:

```
RM1: yarncluster:shared-password:rwa,rm1:secret-password:cd
RM2: yarncluster:shared-password:rwa,rm2:secret-password:cd
```

To remove the entry (not tested) when transitioning from HA to normal mode:
```
/usr/lib/zookeeper/bin/zkCli.sh -server master2.ryba:2181
setAcl /rmstore/ZKRMStateRoot world:anyone:rwacd
rmr /rmstore/ZKRMStateRoot
```

      if ctx.has_module 'ryba/hadoop/yarn_rm'
        ryba.yarn.site['yarn.resourcemanager.recovery.enabled'] ?= 'true'
        ryba.yarn.site['yarn.resourcemanager.work-preserving-recovery.enabled'] ?= 'true'
        ryba.yarn.site['yarn.resourcemanager.am.max-attempts'] ?= '2'
        ryba.yarn.site['yarn.resourcemanager.store.class'] ?= 'org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore'
        zoo_ctxs = ctx.contexts modules: 'ryba/zookeeper/server', require('../../zookeeper/server').configure
        quorum = for zoo_ctx in zoo_ctxs
          "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.config['clientPort']}"
        ryba.yarn.site['yarn.resourcemanager.zk-address'] ?= quorum.join ','
        # https://zookeeper.apache.org/doc/r3.1.2/zookeeperProgrammers.html#sc_ZooKeeperAccessControl
        # ACLs to be used for setting permissions on ZooKeeper znodes.
        ryba.yarn.site['yarn.resourcemanager.zk-acl'] ?= 'sasl:rm:rwcda'
        # About 'yarn.resourcemanager.zk-state-store.root-node.acl'
        # See http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_hag_rm_ha_config.html
        # The ACLs used for the root node of the ZooKeeper state store. The ACLs
        # set here should allow both ResourceManagers to read, write, and
        # administer, with exclusive access to create and delete. If nothing is
        # specified, the root node ACLs are automatically generated on the basis
        # of the ACLs specified through yarn.resourcemanager.zk-acl. But that
        # leaves a security hole in a secure setup. To configure automatic failover:
        ryba.yarn.site['yarn.resourcemanager.zk-state-store.parent-path'] ?= '/rmstore'
        ryba.yarn.site['yarn.resourcemanager.zk-num-retries'] ?= '500'
        ryba.yarn.site['yarn.resourcemanager.zk-retry-interval-ms'] ?= '2000'
        ryba.yarn.site['yarn.resourcemanager.zk-timeout-ms'] ?= '10000'

      if ctx.has_module 'ryba/hadoop/yarn_nm'
        ryba.yarn.site['yarn.nodemanager.recovery.enabled'] ?= 'true'
        ryba.yarn.site['yarn.nodemanager.recovery.dir'] ?= '/var/yarn/recovery-state'

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

[cloudera_ha]: http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_hag_rm_ha_config.html
[cloudera_wp]: http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/admin_ha_yarn_work_preserving_recovery.html
[hdp_wp]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.4/bk_yarn_resource_mgt/content/ch_work-preserving_restart.html
[YARN-128]: https://issues.apache.org/jira/browse/YARN-128
[YARN-128-pdf] https://issues.apache.org/jira/secure/attachment/12552867/RMRestartPhase1.pdf
[YARN-556]: https://issues.apache.org/jira/browse/YARN-556
[YARN-556-pdf]: https://issues.apache.org/jira/secure/attachment/12599562/Work%20Preserving%20RM%20Restart.pdf
