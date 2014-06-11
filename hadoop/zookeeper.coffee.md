---
title: 
layout: module
---

# Zookeeper

    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/commons/java'
    # module.exports.push 'phyla/hadoop/core'

## Configure

*   `zookeeper_user` (object|string)   
    The Unix Zookeeper login name or a user object (see Mecano User documentation).   

```json
{
  "hdp": {
    "zookeeper_user": {
      "name": "zookeeper", "system": true, "gid": "hadoop",
      "comment": "Zookeeper User", "home": "/var/lib/zookeeper"
    }
  }
}

Example :

    module.exports.push module.exports.configure = (ctx) ->
      require('./core').configure ctx
      require('masson/commons/java').configure ctx
      # User
      ctx.config.hdp.zookeeper_user = name: ctx.config.hdp.zookeeper_user if typeof ctx.config.hdp.zookeeper_user is 'string'
      ctx.config.hdp.zookeeper_user ?= {}
      ctx.config.hdp.zookeeper_user.name ?= 'zookeeper'
      ctx.config.hdp.zookeeper_user.system ?= true
      ctx.config.hdp.zookeeper_user.gid ?= 'hadoop'
      ctx.config.hdp.zookeeper_user.comment ?= 'Zookeeper User'
      ctx.config.hdp.zookeeper_user.home ?= '/var/lib/zookeeper'
      # Layout
      ctx.config.hdp.zookeeper_data_dir ?= '/var/zookeper/data/'
      ctx.config.hdp.zookeeper_conf_dir ?= '/etc/zookeeper/conf'
      ctx.config.hdp.zookeeper_log_dir ?= '/var/log/zookeeper'
      ctx.config.hdp.zookeeper_pid_dir ?= '/var/run/zookeeper'
      ctx.config.hdp.zookeeper_port ?= 2181
      # Internal
      ctx.config.hdp.zookeeper_myid ?= null

## Users & Groups

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep zookeeper
zookeeper:x:497:498:ZooKeeper:/var/run/zookeeper:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:498:hdfs
```

    module.exports.push name: 'HDP ZooKeeper # Users & Groups', callback: (ctx, next) ->
      {hadoop_group, zookeeper_user} = ctx.config.hdp
      ctx.group hadoop_group, (err, gmodified) ->
        return next err if err
        ctx.user zookeeper_user, (err, umodified) ->
          next err, if gmodified or umodified then ctx.OK else ctx.PASS

## Install

Follow the [HDP recommandations][install] to install the "zookeeper" package
which has no dependency.

    module.exports.push name: 'HDP ZooKeeper # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service name: 'zookeeper', (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP ZooKeeper # Layout', callback: (ctx, next) ->
      { hadoop_group, zookeeper_user, 
        zookeeper_data_dir, zookeeper_pid_dir, zookeeper_log_dir
      } = ctx.config.hdp
      ctx.mkdir [
        destination: zookeeper_data_dir
        uid: zookeeper_user.name
        gid: hadoop_group.name
        mode: 0o755
      ,
        destination: zookeeper_pid_dir
        uid: zookeeper_user.name
        gid: hadoop_group.name
        mode: 0o755
      ,
        destination: zookeeper_log_dir
        uid: zookeeper_user.name
        gid: hadoop_group.name
        mode: 0o755
      ], (err, modified) ->
        next err, if modified then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP ZooKeeper # Configure', callback: (ctx, next) ->
      modified = false
      hosts = ctx.hosts_with_module 'phyla/hadoop/zookeeper'
      {java_home} = ctx.config.java
      { hadoop_group,
        zookeeper_user, zookeeper_data_dir, zookeeper_pid_dir, zookeeper_log_dir,
        zookeeper_myid, zookeeper_port
      } = ctx.config.hdp
      do_zoo_cfg = ->
        # hosts = for host, i in hosts
        #   "server.#{i+1}=#{host}:2888:3888"
        # hosts = hosts.join '\n'
        ctx.log 'Prepare zoo.cfg mapping'
        mapping = (for host, i in hosts
          "server.#{i+1}=#{host}:2888:3888").join '\n'
        ctx.log 'Write zoo.cfg'
        ctx.write
          content: """
          # The number of milliseconds of each tick
          tickTime=2000
          # The number of ticks that the initial
          # synchronization phase can take
          initLimit=10
          # The number of ticks that can pass between
          # sending a request and getting an acknowledgement
          syncLimit=5
          # the directory where the snapshot is stored.
          dataDir=#{zookeeper_data_dir}
          # the port at which the clients will connect
          clientPort=#{zookeeper_port}
          #{mapping}
          """
          destination: '/etc/zookeeper/conf/zoo.cfg'
        , (err, written) ->
          return next err if err
          modified = true if written
          do_myid()
      do_myid = ->
        unless zookeeper_myid
          for host, i in hosts
            zookeeper_myid = i+1 if host is ctx.config.host
        ctx.log 'Write myid'
        ctx.write
          content: zookeeper_myid
          destination: "#{zookeeper_data_dir}/myid"
          uid: zookeeper_user.name
          gid: hadoop_group.name
        , (err, written) ->
          return next err if err
          modified = true if written
          do_env()
      do_env = ->
        ctx.log 'Write zookeeper-env.sh'
        ctx.write
          content: """
          export JAVA_HOME=#{java_home}
          export ZOO_LOG_DIR=#{zookeeper_log_dir}
          export ZOOPIDFILE=#{zookeeper_pid_dir}/zookeeper_server.pid
          export SERVER_JVMFLAGS= 
          """
          destination: '/etc/zookeeper/conf/zookeeper-env.sh'
        , (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        next null, if modified then ctx.OK else ctx.PASS
      do_zoo_cfg()

    module.exports.push name: 'HDP ZooKeeper # Kerberos', callback: (ctx, next) ->
      {realm} = ctx.config.hdp
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: "zookeeper/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/zookeeper.service.keytab"
        uid: 'zookeeper'
        gid: 'hadoop'
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , (err, created) ->
        next err, if created then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP ZooKeeper # Start', timeout: -1, callback: (ctx, next) ->
      lifecycle.zookeeper_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS

## TODO

*   [Securing access to ZooKeeper](http://hadoop.apache.org/docs/r2.2.0/hadoop-yarn/hadoop-yarn-site/HDFSHighAvailabilityWithNFS.html)

## Resources

*   [ZooKeeper Resilience](http://blog.cloudera.com/blog/2014/03/zookeeper-resilience-at-pinterest/)

[install]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.1-latest/bk_installing_manually_book/content/rpm-zookeeper-1.html




