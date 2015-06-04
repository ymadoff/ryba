
# YARN ResourceManager

[Yarn ResourceManager ](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/ResourceManagerRestart.html) is the central authority that manages resources and schedules applications running atop of YARN.

    module.exports = []

## Configuration

    module.exports.configure = (ctx) ->
      require('../yarn_client').configure ctx
      {ryba} = ctx.config
      ryba.yarn.site['yarn.resourcemanager.keytab'] ?= '/etc/security/keytabs/rm.service.keytab'
      ryba.yarn.site['yarn.resourcemanager.principal'] ?= "rm/#{ryba.static_host}@#{ryba.realm}"
      ryba.yarn.site['yarn.resourcemanager.scheduler.class'] ?= 'org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler'


## Configuration for Memory and CPU

hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar pi -Dmapreduce.map.cpu.vcores=32 1 1

The value for the yarn.scheduler.maximum-allocation-vcores should not be larger
than the value for the yarn.nodemanager.resource.cpu-vcores parameter on any
NodeManager. Document states that resource requests are capped at the maximum
allocation limit and a container is eventually granted. Tests in version 2.4
instead shows that the containers are never granted, and no progress is made by
the application (zombie state).

      ryba.yarn.capacity_scheduler ?= {}
      ryba.yarn.capacity_scheduler['yarn.scheduler.capacity.resource-calculator'] ?= 'org.apache.hadoop.yarn.util.resource.DominantResourceCalculator'
      ryba.yarn.site['yarn.scheduler.minimum-allocation-mb'] ?= '256'
      ryba.yarn.site['yarn.scheduler.maximum-allocation-mb'] ?= '2048'
      ryba.yarn.site['yarn.scheduler.minimum-allocation-vcores'] ?= 1
      ryba.yarn.site['yarn.scheduler.maximum-allocation-vcores'] ?= 32

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


