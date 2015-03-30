
# YARN ResourceManager

    module.exports = []

## Configuration

    module.exports.configure = (ctx) ->
      require('../yarn_client').configure ctx
      {ryba} = ctx.config
      ryba.yarn.site['yarn.resourcemanager.keytab'] ?= '/etc/security/keytabs/rm.service.keytab'
      ryba.yarn.site['yarn.resourcemanager.principal'] ?= "rm/#{ryba.static_host}@#{ryba.realm}"
      ryba.yarn.site['yarn.resourcemanager.scheduler.class'] ?= 'org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler'

## Configuration for ZooKeeper

ZooKeeper is used in the context of restart recovering and high availability.

About the 'root-node.acl', the [mailing list][ml_root_acl] mentions:

> For the exclusive create-delete access, the RMs use username:password where
the username is yarn.resourcemanager.address and the password is a secure random
number. One should use that config only when they are not happy with this
implicit default mechanism.

Here's an example:

```
RM1: yarncluster:shared-password:rwa,rm1:secret-password:cd
RM2: yarncluster:shared-password:rwa,rm2:secret-password:cd
```

To remove the entry (not yet tested) when transitioning from HA to normal mode:
```
/usr/lib/zookeeper/bin/zkCli.sh -server master2.ryba:2181
setAcl /rmstore/ZKRMStateRoot world:anyone:rwacd
rmr /rmstore/ZKRMStateRoot
```

      zoo_ctxs = ctx.contexts modules: 'ryba/zookeeper/server', require('../../zookeeper/server').configure
      quorum = for zoo_ctx in zoo_ctxs
        "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.config['clientPort']}"
      ryba.yarn.site['yarn.resourcemanager.zk-address'] ?= quorum.join ','
      # https://zookeeper.apache.org/doc/r3.1.2/zookeeperProgrammers.html#sc_ZooKeeperAccessControl
      # ACLs to be used for setting permissions on ZooKeeper znodes.
      ryba.yarn.site['yarn.resourcemanager.zk-acl'] ?= 'sasl:rm:rwcda'

## Configuration for automatic failover

      ryba.yarn.site['yarn.resourcemanager.ha.automatic-failover.enabled'] ?= 'true'
      ryba.yarn.site['yarn.resourcemanager.ha.automatic-failover.embedded'] ?= 'true'
      ryba.yarn.site['yarn.resourcemanager.cluster-id'] ?= 'yarn_cluster_01'

## Configuration for Restart Recovery

[ResourceManager Restart][restart] is a feature that enhances ResourceManager to
keep functioning across restarts and also makes ResourceManager down-time
invisible to end-users.

HDP companion files enable by default the recovery mode. Its implementation
default to the ZooKeeper based state-store implementation. Unless specified,
the root znode where the ResourceManager state is stored is inside "/rmstore".

      ryba.yarn.site['yarn.resourcemanager.recovery.enabled'] ?= 'true'
      ryba.yarn.site['yarn.resourcemanager.store.class'] ?= 'org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore'

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


