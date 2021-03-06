
# YARN NodeManager Configuration

## Exemple

```json
{ "ryba": { "yarn": { "nm": {
    "opts": "",
    "heapsize": "1024"
} } } }
```

    module.exports = ->
      rm_ctxs = @contexts 'ryba/hadoop/yarn_rm', require('../yarn_rm/configure').handler
      [ats_ctx] = @contexts 'ryba/hadoop/yarn_ts', require('../yarn_ts/configure').handler
      {host, ryba} = @config

## Environnment

      ryba.yarn.libexec ?= '/usr/hdp/current/hadoop-client/libexec'
      ryba.yarn.nm ?= {}
      ryba.yarn.nm.home ?= '/usr/hdp/current/hadoop-yarn-nodemanager'
      ryba.yarn.nm.log_dir ?= '/var/log/hadoop-yarn'
      ryba.yarn.nm.pid_dir ?= '/var/run/hadoop-yarn'
      ryba.yarn.nm.conf_dir ?= '/etc/hadoop-yarn-nodemanager/conf'
      ryba.yarn.nm.opts ?= {}
      ryba.yarn.nm.java_opts ?= ''
      ryba.yarn.nm.heapsize ?= '1024'

## Configuration

      ryba.yarn.site['yarn.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      # Working Directories (see capacity for server resource discovery)
      ryba.yarn.site['yarn.nodemanager.local-dirs'] ?= ['/var/yarn/local']
      ryba.yarn.site['yarn.nodemanager.local-dirs'] = ryba.yarn.site['yarn.nodemanager.local-dirs'].join ',' if Array.isArray ryba.yarn.site['yarn.nodemanager.local-dirs']
      ryba.yarn.site['yarn.nodemanager.log-dirs'] ?= ['/var/yarn/logs']
      ryba.yarn.site['yarn.nodemanager.log-dirs'] = ryba.yarn.site['yarn.nodemanager.log-dirs'].join ',' if Array.isArray ryba.yarn.site['yarn.nodemanager.log-dirs']
      # Configuration
      # ryba.yarn.site['yarn.scheduler.minimum-allocation-mb'] ?= null # Make sure we erase hdp default value
      # ryba.yarn.site['yarn.scheduler.maximum-allocation-mb'] ?= null # Make sure we erase hdp default value
      ryba.yarn.site['yarn.nodemanager.address'] ?= "#{host}:45454"
      ryba.yarn.site['yarn.nodemanager.localizer.address'] ?= "#{host}:8040"
      ryba.yarn.site['yarn.nodemanager.webapp.address'] ?= "#{host}:8042"
      ryba.yarn.site['yarn.nodemanager.webapp.https.address'] ?= "#{host}:8044"
      ryba.yarn.site['yarn.nodemanager.remote-app-log-dir'] ?= "/app-logs"
      ryba.yarn.site['yarn.nodemanager.keytab'] ?= '/etc/security/keytabs/nm.service.keytab'
      ryba.yarn.site['yarn.nodemanager.principal'] ?= "nm/_HOST@#{ryba.realm}"
      ryba.yarn.site['yarn.nodemanager.vmem-pmem-ratio'] ?= '2.1'
      # Cloudera recommand setting [vmem-check to false on Centos/RHEL 6 due to its aggressive allocation of virtual memory](http://blog.cloudera.com/blog/2014/04/apache-hadoop-yarn-avoiding-6-time-consuming-gotchas/)
      # by default, "yarn.nodemanager.vmem-check-enabled" is true (see in yarn-default.xml)
      ryba.yarn.site['yarn.nodemanager.pmem-check-enabled'] ?= 'true'
      ryba.yarn.site['yarn.nodemanager.vmem-check-enabled'] ?= 'true'
      ryba.yarn.site['yarn.nodemanager.resource.percentage-physical-cpu-limit'] ?= '100'
      ryba.yarn.site['yarn.nodemanager.container-executor.class'] ?= 'org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor'
      ryba.yarn.site['yarn.nodemanager.linux-container-executor.group'] ?= 'yarn'
      ryba.yarn.site['yarn.nodemanager.linux-container-executor.cgroups.strict-resource-usage'] ?= 'false' # By default, iyarn.nodemanager.container-executor.clasf spare CPU cycles are available, containers are allowed to exceed the CPU limits set for them
      # Fix bug in HDP companion files (missing "s")
      ryba.yarn.site['yarn.nodemanager.log.retain-second'] ?= null
      ryba.yarn.site['yarn.nodemanager.log.retain-seconds'] ?= '604800'
      # Configurations for History Server (Not sure wether this should be deployed on NMs):
      ryba.yarn.site['yarn.log-aggregation-enable'] ?= 'true'
      ryba.yarn.site['yarn.log-aggregation.retain-seconds'] ?= '2592000' #  30 days, how long to keep aggregation logs before deleting them. -1 disables. Be careful, set this too small and you will spam the name node.
      ryba.yarn.site['yarn.log-aggregation.retain-check-interval-seconds'] ?= '-1' # Time between checks for aggregated log retention. If set to 0 or a negative value then the value is computed as one-tenth of the aggregated log retention time. Be careful, set this too small and you will spam the name node.

## Container Executor

[YARN containers][container] in a secure cluster use the operating system 
facilities to offer execution isolation for containers. Secure containers 
execute under the credentials of the job user. The operating system enforces 
access restriction for the container. The container must run as the use that 
submitted the application.

Secure Containers work only in the context of secured YARN clusters.

      ryba.container_executor ?= {}
      ryba.container_executor['yarn.nodemanager.local-dirs'] ?= ryba.yarn.site['yarn.nodemanager.local-dirs']
      ryba.container_executor['yarn.nodemanager.linux-container-executor.group'] ?= ryba.yarn.site['yarn.nodemanager.linux-container-executor.group']
      ryba.container_executor['yarn.nodemanager.log-dirs'] = ryba.yarn.site['yarn.nodemanager.log-dirs']
      ryba.container_executor['banned.users'] ?= 'hdfs,yarn,mapred,bin'
      ryba.container_executor['min.user.id'] ?= '0'
      for rm_ctx in rm_ctxs
        id = if rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.id']}" else ''
        for property in [
          'yarn.http.policy'
          'yarn.log.server.url'
          'yarn.resourcemanager.principal'
          'yarn.resourcemanager.cluster-id'
          'yarn.nodemanager.remote-app-log-dir'
          'yarn.nodemanager.remote-app-log-dir-suffix'
          'yarn.resourcemanager.ha.enabled'
          'yarn.resourcemanager.ha.rm-ids'
          'yarn.resourcemanager.webapp.delegation-token-auth-filter.enabled'
          "yarn.resourcemanager.address#{id}"
          "yarn.resourcemanager.scheduler.address#{id}"
          "yarn.resourcemanager.admin.address#{id}"
          "yarn.resourcemanager.webapp.address#{id}"
          "yarn.resourcemanager.webapp.https.address#{id}"
          "yarn.resourcemanager.resource-tracker.address#{id}"
        ]
          @config.ryba.yarn.site[property] ?= rm_ctx.config.ryba.yarn.rm.site[property]

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

## Work Preserving Recovery

See ResourceManager for additionnal informations.

      ryba.yarn.site['yarn.nodemanager.recovery.enabled'] ?= 'true'
      ryba.yarn.site['yarn.nodemanager.recovery.dir'] ?= '/var/yarn/recovery-state'

## Configuration for CGroups

Resources:
*   [YARN-600: Hook up cgroups CPU settings to the number of virtual cores allocated](https://issues.apache.org/jira/browse/YARN-600)
*   [YARN-810: CGroup ceiling enforcement on CPU](https://issues.apache.org/jira/browse/YARN-810)
*   [Using YARN with Cgroups](http://riccomini.name/posts/hadoop/2013-06-14-yarn-with-cgroups/)
*   [VCore Configuration In Hadoop](http://jason4zhu.blogspot.fr/2014/10/vcore-configuration-in-hadoop.html)

      # isLinuxContainer = ryba.yarn.site['yarn.nodemanager.container-executor.class'] is 'org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor'
      # ryba.yarn.site['yarn.nodemanager.linux-container-executor.resources-handler.class'] ?= 'org.apache.hadoop.yarn.server.nodemanager.util.CgroupsLCEResourcesHandler'
      # ryba.yarn.site['yarn.nodemanager.linux-container-executor.cgroups.hierarchy'] ?= '/hadoop-yarn'
      # ryba.yarn.site['yarn.nodemanager.linux-container-executor.cgroups.mount'] ?= 'true'
      # ryba.yarn.site['yarn.nodemanager.linux-container-executor.cgroups.mount-path'] ?= '/cgroup'
      ryba.yarn.site['yarn.nodemanager.linux-container-executor.resources-handler.class'] ?= 'org.apache.hadoop.yarn.server.nodemanager.util.CgroupsLCEResourcesHandler'
      hierarchy = ryba.yarn.site['yarn.nodemanager.linux-container-executor.cgroups.hierarchy'] ?= "/#{ryba.yarn.user.name}"
      ryba.yarn.site['yarn.nodemanager.linux-container-executor.cgroups.mount'] ?= 'false'
      ryba.yarn.site['yarn.nodemanager.linux-container-executor.cgroups.mount-path'] ?= '/cgroup'
      # HDP doc, probably incorrect
      # ryba.yarn.site['yarn.nodemanager.container-executor.cgroups.hierarchy'] ?= ryba.yarn.site['yarn.nodemanager.linux-container-executor.cgroups.hierarchy']
      # ryba.yarn.site['yarn.nodemanager.container-executor.cgroups.mount'] ?= ryba.yarn.site['yarn.nodemanager.linux-container-executor.cgroups.mount']
      # ryba.yarn.site['yarn.nodemanager.container-executor.resources-handler.class'] ?= ryba.yarn.site['yarn.nodemanager.container-executor.resources-handler.class']
      # ryba.yarn.site['yarn.nodemanager.container-executor.group'] ?= 'hadoop'
      if ryba.yarn.site['yarn.nodemanager.linux-container-executor.cgroups.mount'] is 'false'
        # default values
        ryba.yarn.cgroup ?=
          "#{ryba.yarn.user.name}":
            perm:
              task:
                'uid': "#{ryba.yarn.user.name}"
                'gid': "#{ryba.yarn.user.name}"
              admin:
                'uid': "#{ryba.yarn.user.name}"
                'gid': "#{ryba.yarn.user.name}"
            cpu:
              'cpu.rt_period_us': "\"1000000\""
              'cpu.rt_runtime_us': "\"0\""
              'cpu.cfs_period_us': "\"100000\""
              'cpu.cfs_quota_us': "\"-1\""
              'cpu.shares': '\"1024\"'


## List of Services

      ryba.yarn.site['yarn.nodemanager.aux-services'] ?= 'mapreduce_shuffle'
      ryba.yarn.site['yarn.nodemanager.aux-services.mapreduce_shuffle.class'] ?= 'org.apache.hadoop.mapred.ShuffleHandler'

## Ranger Plugin Configuration

      @config.ryba.yarn_plugin_is_master = false

## Dependencies

    {merge} = require 'nikita/lib/misc'

[yarn-cgroup-red7]: https://issues.apache.org/jira/browse/YARN-2194
[container]: http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/SecureContainer.html
