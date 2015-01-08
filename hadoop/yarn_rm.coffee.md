---
title: 
layout: module
---

# YARN ResourceManager

    module.exports = []

## Configuration

    module.exports.configure = (ctx) ->
      require('./yarn').configure ctx
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

      zoo_ctxs = ctx.contexts modules: 'ryba/zookeeper/server', require('../zookeeper/server').configure
      quorum = for zoo_ctx in zoo_ctxs
        "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.config['clientPort']}"
      ryba.yarn.site['yarn.resourcemanager.zk-address'] ?= quorum.join ','
      # https://zookeeper.apache.org/doc/r3.1.2/zookeeperProgrammers.html#sc_ZooKeeperAccessControl
      # ACLs to be used for setting permissions on ZooKeeper znodes.
      ryba.yarn.site['yarn.resourcemanager.zk-acl'] ?= 'world:anyone:rwcda'
      # TODO: not sure how to configure this
      # The ACLs used for the root node of the ZooKeeper state store. The ACLs
      # set here should allow both ResourceManagers to read, write, and
      # administer, with exclusive access to create and delete. If nothing is
      # specified, the root node ACLs are automatically generated on the basis
      # of the ACLs specified through yarn.resourcemanager.zk-acl. But that
      # leaves a security hole in a secure setup.
      ryba.yarn.site['yarn.resourcemanager.zk-state-store.root-node.acl'] ?= ''

## Configuration for automatic failover

      ryba.yarn.site['yarn.resourcemanager.ha.automatic-failover.enabled'] ?= 'true'
      ryba.yarn.site['yarn.resourcemanager.ha.automatic-failover.embedded'] ?= 'true'
      ryba.yarn.site['yarn.resourcemanager.cluster-id'] ?= 'yarn_cluster_01'

## Configuration for Restart Recovering

[ResourceManager Restart][restart] is a feature that enhances ResourceManager to
keep functioning across restarts and also makes ResourceManager down-time
invisible to end-users.

HDP companion files enable by default the recovery mode. Its implementation
default to the ZooKeeper based state-store implementation. Unless specified,
the root znode where the ResourceManager state is stored is inside "/rmstore".

      ryba.yarn.site['yarn.resourcemanager.recovery.enabled'] ?= 'true'
      ryba.yarn.site['yarn.resourcemanager.store.class'] ?= 'org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore'

    # module.exports.push commands: 'backup', modules: 'ryba/hadoop/yarn_rm_backup'

    module.exports.push commands: 'check', modules: 'ryba/hadoop/yarn_rm_check'

    module.exports.push commands: 'info', modules: 'ryba/hadoop/yarn_rm_info'

    module.exports.push commands: 'install', modules: [
      'ryba/hadoop/yarn_rm_install'
      'ryba/hadoop/yarn_rm_start'
      'ryba/hadoop/yarn_rm_check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/hadoop/yarn_rm_start'

    module.exports.push commands: 'status', modules: 'ryba/hadoop/yarn_rm_status'

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/yarn_rm_stop'


[restart]: http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/ResourceManagerRestart.html
[ml_root_acl]: http://lucene.472066.n3.nabble.com/Yarn-HA-Zookeeper-ACLs-td4138735.html


