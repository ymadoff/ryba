
## Configuration

```json
{ "ryba": { "yarn": { "rm": {
    "opts": "",
    "heapsize": "1024"
} } } }
```

    module.exports = handler: ->
      zk_ctxs = @contexts 'ryba/zookeeper/server', require('../../zookeeper/server/configure').handler
      [jhs_ctx] = @contexts 'ryba/hadoop/mapred_jhs', require('../mapred_jhs/configure').handler
      [ats_ctx] = @contexts 'ryba/hadoop/yarn_ts', require('../yarn_ts/configure').handler
      rm_ctxs = @contexts 'ryba/hadoop/yarn_rm'
      {ryba} = @config
      ryba.yarn.home ?= '/usr/hdp/current/hadoop-yarn-client'
      ryba.yarn.log_dir ?= '/var/log/hadoop-yarn'
      ryba.yarn.pid_dir ?= '/var/run/hadoop-yarn'
      ryba.yarn.rm ?= {}
      ryba.yarn.rm.conf_dir ?= '/etc/hadoop-yarn-resourcemanager/conf'
      ryba.yarn.rm.core_site ?= {}
      # Enable JAAS/Kerberos connection between YARN RM and ZooKeeper
      ryba.yarn.rm.opts ?= ''
      ryba.yarn.rm.opts = "-Djava.security.auth.login.config=#{ryba.yarn.rm.conf_dir}/yarn-rm.jaas #{ryba.yarn.rm.opts}"
      ryba.yarn.rm.heapsize ?= '1024'
      ryba.yarn.rm.site ?= {}
      # Configuration
      ryba.yarn.rm.site['yarn.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      ryba.yarn.rm.site['yarn.resourcemanager.ha.id'] ?= @config.shortname
      ryba.yarn.rm.site['yarn.resourcemanager.nodes.include-path'] ?= "#{ryba.yarn.rm.conf_dir}/yarn.include"
      ryba.yarn.rm.site['yarn.resourcemanager.nodes.exclude-path'] ?= "#{ryba.yarn.rm.conf_dir}/yarn.exclude"
      ryba.yarn.rm.site['yarn.resourcemanager.keytab'] ?= '/etc/security/keytabs/rm.service.keytab'
      ryba.yarn.rm.site['yarn.resourcemanager.principal'] ?= "rm/#{ryba.static_host}@#{ryba.realm}"
      ryba.yarn.rm.site['yarn.resourcemanager.scheduler.class'] ?= 'org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler'

## Configuration for Memory and CPU

hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar pi -Dmapreduce.map.cpu.vcores=32 1 1

The value for the yarn.scheduler.maximum-allocation-vcores should not be larger
than the value for the yarn.nodemanager.resource.cpu-vcores parameter on any
NodeManager. Document states that resource requests are capped at the maximum
allocation limit and a container is eventually granted. Tests in version 2.4
instead shows that the containers are never granted, and no progress is made by
the application (zombie state).

      ryba.yarn.rm.site['yarn.scheduler.minimum-allocation-mb'] ?= '256'
      ryba.yarn.rm.site['yarn.scheduler.maximum-allocation-mb'] ?= '2048'
      ryba.yarn.rm.site['yarn.scheduler.minimum-allocation-vcores'] ?= 1
      ryba.yarn.rm.site['yarn.scheduler.maximum-allocation-vcores'] ?= 32

## Zookeeper

The Zookeeper quorum is used for HA and recovery. High availability
with automatic failover stores information inside "yarn.resourcemanager.ha.automatic-failover.zk-base-path"
(default to "/yarn-leader-election"). Work preserving recovery stores
information inside "yarn.resourcemanager.zk-state-store.parent-path" (default to
"/rmstore").

      quorum = for zk_ctx in zk_ctxs
        "#{zk_ctx.config.host}:#{zk_ctx.config.ryba.zookeeper.config['clientPort']}"
      ryba.yarn.rm.site['yarn.resourcemanager.zk-address'] ?= quorum.join ','
      
## MapReduce JobHistory Server
      
      if jhs_ctx
        ryba.yarn.rm.site['mapreduce.jobhistory.principal'] ?= jhs_ctx.config.ryba.mapred.site['mapreduce.jobhistory.principal']
        ryba.yarn.rm.site['yarn.resourcemanager.bind-host'] ?= '0.0.0.0'
        # TODO: detect https and port, see "../mapred_jhs/check"
        jhs_protocol = if jhs_ctx.config.ryba.mapred.site['mapreduce.jobhistory.address'] is 'HTTP_ONLY' then 'http' else 'https'
        jhs_protocol_key = if jhs_protocol is 'http' then '' else '.https'
        jhs_address = jhs_ctx.config.ryba.mapred.site["mapreduce.jobhistory.webapp#{jhs_protocol_key}.address"]
        ryba.yarn.site['yarn.log.server.url'] ?= "#{jhs_protocol}://#{jhs_address}/jobhistory/logs/"

## High Availability with Manual Failover

Cloudera [High Availability Guide][cloudera_ha] provides a nice documentation
about each configuration and where they should apply.

Unless specified otherwise, the active ResourceManager is the first one defined
inside the configuration.

      rm_shortnames = for rm_ctx in rm_ctxs then rm_ctx.config.shortname
      is_ha = rm_ctxs.length > 1
      # ryba.yarn.active_rm_host ?= if is_ha then rm_ctxs[0].config.host else null
      ryba.yarn.rm.site['yarn.resourcemanager.ha.enabled'] ?= if is_ha then 'true' else 'false'
      if ryba.yarn.rm.site['yarn.resourcemanager.ha.enabled'] is 'true'
        ryba.yarn.rm.site['yarn.resourcemanager.cluster-id'] ?= 'yarn_cluster_01'
        ryba.yarn.rm.site['yarn.resourcemanager.ha.rm-ids'] ?= rm_shortnames.join ',' if is_ha
        # Flag to enable override of the default kerberos authentication
        # filter with the RM authentication filter to allow authentication using
        # delegation tokens(fallback to kerberos if the tokens are missing)
        ryba.yarn.rm.site["yarn.resourcemanager.webapp.delegation-token-auth-filter.enabled"] ?= "true" # YARN default is "true"
        for rm_ctx in rm_ctxs
          id = if ryba.yarn.rm.site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.id']}" else ''
          ryba.yarn.rm.site["yarn.resourcemanager.address#{id}"] ?= "#{rm_ctx.config.host}:8050"
          ryba.yarn.rm.site["yarn.resourcemanager.scheduler.address#{id}"] ?= "#{rm_ctx.config.host}:8030"
          ryba.yarn.rm.site["yarn.resourcemanager.admin.address#{id}"] ?= "#{rm_ctx.config.host}:8141"
          ryba.yarn.rm.site["yarn.resourcemanager.webapp.address#{id}"] ?= "#{rm_ctx.config.host}:8088"
          ryba.yarn.rm.site["yarn.resourcemanager.webapp.https.address#{id}"] ?= "#{rm_ctx.config.host}:8090"
          ryba.yarn.rm.site["yarn.resourcemanager.resource-tracker.address#{id}"] ?= "#{rm_ctx.config.host}:8025"

## High Availability with optional automatic failover

      ryba.yarn.rm.site['yarn.resourcemanager.ha.automatic-failover.enabled'] ?= 'true'
      ryba.yarn.rm.site['yarn.resourcemanager.ha.automatic-failover.embedded'] ?= 'true'
      ryba.yarn.rm.site['yarn.resourcemanager.ha.automatic-failover.zk-base-path'] ?= '/yarn-leader-election'

## Preemption

Preemption is enabled by default. With Preemption, under-served queues can begin
to claim their allocated cluster resources almost immediately, without having to
wait for other queues' applications to finish running. Containers are only
killed as a last resort.

      # Enables preemption
      ryba.yarn.rm.site['yarn.resourcemanager.scheduler.monitor.enable'] ?= 'true'
      # List of SchedulingEditPolicy classes that interact with the scheduler.
      ryba.yarn.rm.site['yarn.resourcemanager.scheduler.monitor.policies'] ?= 'org.apache.hadoop.yarn.server.resourcemanager.monitor.capacity.ProportionalCapacityPreemptionPolicy'
      # The time in milliseconds between invocations of this policy.
      ryba.yarn.rm.site['yarn.resourcemanager.monitor.capacity.preemption.monitoring_interva'] ?= '3000'
      # The time in milliseconds between requesting a preemption from an application and killing the container.
      ryba.yarn.rm.site['yarn.resourcemanager.monitor.capacity.preemption.max_wait_before_kill'] ?= '15000'
      # The maximum percentage of resources preempted in a single round.
      ryba.yarn.rm.site['yarn.resourcemanager.monitor.capacity.preemption.total_preemption_per_round'] ?= '0.1'

## [Work Preserving Recovery][restart]

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

      ryba.yarn.rm.site['yarn.resourcemanager.recovery.enabled'] ?= 'true'
      ryba.yarn.rm.site['yarn.resourcemanager.work-preserving-recovery.enabled'] ?= 'true'
      ryba.yarn.rm.site['yarn.resourcemanager.am.max-attempts'] ?= '2'
      ryba.yarn.rm.site['yarn.resourcemanager.store.class'] ?= 'org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore'
      # https://zookeeper.apache.org/doc/r3.1.2/zookeeperProgrammers.html#sc_ZooKeeperAccessControl
      # ACLs to be used for setting permissions on ZooKeeper znodes.
      ryba.yarn.rm.site['yarn.resourcemanager.zk-acl'] ?= 'sasl:rm:rwcda'
      # About 'yarn.resourcemanager.zk-state-store.root-node.acl'
      # See http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_hag_rm_ha_config.html
      # The ACLs used for the root node of the ZooKeeper state store. The ACLs
      # set here should allow both ResourceManagers to read, write, and
      # administer, with exclusive access to create and delete. If nothing is
      # specified, the root node ACLs are automatically generated on the basis
      # of the ACLs specified through yarn.resourcemanager.zk-acl. But that
      # leaves a security hole in a secure setup. To configure automatic failover:
      ryba.yarn.rm.site['yarn.resourcemanager.zk-state-store.parent-path'] ?= '/rmstore'
      ryba.yarn.rm.site['yarn.resourcemanager.zk-num-retries'] ?= '500'
      ryba.yarn.rm.site['yarn.resourcemanager.zk-retry-interval-ms'] ?= '2000'
      ryba.yarn.rm.site['yarn.resourcemanager.zk-timeout-ms'] ?= '10000'

## Capacity Scheduler

      # TODO Capacity Scheduler node_labels http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_yarn_resource_mgt/content/configuring_node_labels.html
      ryba.capacity_scheduler ?= {}
      ryba.capacity_scheduler['yarn.scheduler.capacity.default.minimum-user-limit-percent'] ?= '100'
      ryba.capacity_scheduler['yarn.scheduler.capacity.maximum-am-resource-percent'] ?= '0.2'
      ryba.capacity_scheduler['yarn.scheduler.capacity.maximum-applications'] ?= '10000'
      ryba.capacity_scheduler['yarn.scheduler.capacity.node-locality-delay'] ?= '40'
      ryba.capacity_scheduler['yarn.scheduler.capacity.resource-calculator'] ?= 'org.apache.hadoop.yarn.util.resource.DominantResourceCalculator'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.accessible-node-labels'] ?= null
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.accessible-node-labels.default.capacity'] ?= null # was 100
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.accessible-node-labels.default.maximum-capacity'] ?= null # was 100
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.acl_administer_queue'] ?= '*'
      # ryba.capacity_scheduler['yarn.scheduler.capacity.root.capacity'] ?= '100'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.default-node-label-expression'] ?= ' '
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.default.acl_administer_jobs'] ?= '*'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.default.acl_submit_applications'] ?= '*'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.default.capacity'] ?= '100'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.default.maximum-capacity'] ?= '100'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.default.state'] ?= 'RUNNING'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.default.user-limit-factor'] ?= '1'
      # Defines root's child queue named 'default'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.queues'] ?= 'default'
      ryba.capacity_scheduler['yarn.scheduler.capacity.queue-mappings'] ?= '' # Introduce by hadoop 2.7
      ryba.capacity_scheduler['yarn.scheduler.capacity.queue-mappings-override.enable'] ?= 'false' # Introduce by hadoop 2.7
      
      # ryba.yarn.rm.site['yarn.log-aggregation-enable'] ?= 'true'
      # ryba.yarn.rm.site['yarn.log-aggregation.retain-seconds'] ?= '2592000' #  30 days, how long to keep aggregation logs before deleting them. -1 disables. Be careful, set this too small and you will spam the name node.
      # ryba.yarn.rm.site['yarn.log-aggregation.retain-check-interval-seconds'] ?= '-1' # Time between checks for aggregated log retention. If set to 0 or a negative value then the value is computed as one-tenth of the aggregated log retention time. Be careful, set this too small and you will spam the name node.
      
## Yarn Timeline Server

      for property in [
        'yarn.timeline-service.enabled'
        'yarn.timeline-service.address'
        'yarn.timeline-service.webapp.address'
        'yarn.timeline-service.webapp.https.address'
        'yarn.timeline-service.principal'
        'yarn.timeline-service.http-authentication.type'
        'yarn.timeline-service.http-authentication.kerberos.principal'
      ]
        ryba.yarn.site[property] ?= if ats_ctx then ats_ctx.config.ryba.yarn.site[property] else null
