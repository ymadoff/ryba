
# YARN ResourceManager

[Yarn ResourceManager ](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/ResourceManagerRestart.html) is the central authority that manages resources and schedules applications running atop of YARN.

    module.exports = []

## Configuration

    module.exports.configure = (ctx) ->
      return if ctx.yarn_rm_configured
      ctx.yarn_rm_configured = true
      require('../yarn_client').configure ctx
      {ryba} = ctx.config
      ryba.yarn.site['yarn.resourcemanager.keytab'] ?= '/etc/security/keytabs/rm.service.keytab'
      ryba.yarn.site['yarn.resourcemanager.principal'] ?= "rm/#{ryba.static_host}@#{ryba.realm}"
      ryba.yarn.site['yarn.resourcemanager.scheduler.class'] ?= 'org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler'
      # MapReduce JobHistory Server
      [jhs_ctx] = ctx.contexts 'ryba/hadoop/mapred_jhs', require('../mapred_jhs').configure
      jhs_properties = [
        'mapreduce.jobhistory.principal'
      ]
      for property in jhs_properties
        ryba.mapred.site[property] ?= if jhs_ctx then jhs_ctx.config.ryba.mapred.site[property] else null

## Configuration for Memory and CPU

hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar pi -Dmapreduce.map.cpu.vcores=32 1 1

The value for the yarn.scheduler.maximum-allocation-vcores should not be larger
than the value for the yarn.nodemanager.resource.cpu-vcores parameter on any
NodeManager. Document states that resource requests are capped at the maximum
allocation limit and a container is eventually granted. Tests in version 2.4
instead shows that the containers are never granted, and no progress is made by
the application (zombie state).

      ryba.yarn.site['yarn.scheduler.minimum-allocation-mb'] ?= '256'
      ryba.yarn.site['yarn.scheduler.maximum-allocation-mb'] ?= '2048'
      ryba.yarn.site['yarn.scheduler.minimum-allocation-vcores'] ?= 1
      ryba.yarn.site['yarn.scheduler.maximum-allocation-vcores'] ?= 32

## Capacity Scheduler

      ryba.capacity_scheduler ?= {}
      ryba.capacity_scheduler['yarn.scheduler.capacity.resource-calculator'] ?= 'org.apache.hadoop.yarn.util.resource.DominantResourceCalculator'
      ryba.capacity_scheduler['yarn.scheduler.capacity.default.minimum-user-limit-percent'] ?= '100'
      ryba.capacity_scheduler['yarn.scheduler.capacity.maximum-am-resource-percent'] ?= '0.2'
      ryba.capacity_scheduler['yarn.scheduler.capacity.maximum-applications'] ?= '10000'
      ryba.capacity_scheduler['yarn.scheduler.capacity.node-locality-delay'] ?= '40'
      ryba.capacity_scheduler['yarn.scheduler.capacity.resource-calculator'] ?= 'org.apache.hadoop.yarn.util.resource.DefaultResourceCalculator'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.accessible-node-labels'] ?= '*'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.accessible-node-labels.default.capacity'] ?= '100'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.accessible-node-labels.default.maximum-capacity'] ?= '100'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.acl_administer_queue'] ?= '*'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.capacity'] ?= '100'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.default-node-label-expression'] ?= ' '
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.default.acl_administer_jobs'] ?= '*'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.default.acl_submit_applications'] ?= '*'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.default.capacity'] ?= '100'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.default.maximum-capacity'] ?= '100'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.default.state'] ?= 'RUNNING'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.default.user-limit-factor'] ?= '1'
      ryba.capacity_scheduler['yarn.scheduler.capacity.root.queues'] ?= 'default'

## Capacity Scheduler

Preemption is enabled by default. With Preemption, under-served queues can begin
to claim their allocated cluster resources almost immediately, without having to
wait for other queues' applications to finish running. Containers are only
killed as a last resort.

      # Enables preemption
      ryba.yarn.site['yarn.resourcemanager.scheduler.monitor.enable'] ?= 'true'
      # List of SchedulingEditPolicy classes that interact with the scheduler.
      ryba.yarn.site['yarn.resourcemanager.scheduler.monitor.policies'] ?= 'org.apache.hadoop.yarn.server.resourcemanager.monitor.capacity.ProportionalCapacityPreemptionPolicy'
      # The time in milliseconds between invocations of this policy.
      ryba.yarn.site['yarn.resourcemanager.monitor.capacity.preemption.monitoring_interva'] ?= '3000'
      # The time in milliseconds between requesting a preemption from an application and killing the container.
      ryba.yarn.site['yarn.resourcemanager.monitor.capacity.preemption.max_wait_before_kill'] ?= '15000'
      # The maximum percentage of resources preempted in a single round.
      ryba.yarn.site['yarn.resourcemanager.monitor.capacity.preemption.total_preemption_per_round'] ?= '0.1'

## Environment

      ryba.yarn.rm_opts ?= ''

## Commands

    # module.exports.push commands: 'backup', modules: 'ryba/hadoop/yarn_rm/backup'

    module.exports.push commands: 'check', modules: 'ryba/hadoop/yarn_rm/check'

    module.exports.push commands: 'report', modules: 'ryba/hadoop/yarn_rm/report'

    module.exports.push commands: 'install', modules: [
      'ryba/hadoop/yarn_rm/install'
      'ryba/hadoop/yarn_rm/start'
      'ryba/hadoop/yarn_rm/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/hadoop/yarn_rm/start'

    module.exports.push commands: 'status', modules: 'ryba/hadoop/yarn_rm/status'

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/yarn_rm/stop'


[restart]: http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/ResourceManagerRestart.html
[ml_root_acl]: http://lucene.472066.n3.nabble.com/Yarn-HA-Zookeeper-ACLs-td4138735.html


