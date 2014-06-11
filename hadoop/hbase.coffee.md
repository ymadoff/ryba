---
title: 
layout: module
---

# HBase

    hproperties = require './lib/properties'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/yum'

## Configure

*   `hbase_user` (object|string)   
    The Unix HBase login name or a user object (see Mecano User documentation).   
*   `hbase_group` (object|string)   
    The Unix HBase group name or a group object (see Mecano Group documentation).   

Example

```json
    "hbase_user": {
      "name": "hbase", "system": true, "gid": "hbase",
      "comment": "HBase User", "home": "/var/run/hbase"
    }
    "hbase_group": {
      "name": "HBase", "system": true
    }
```

    module.exports.push module.exports.configure = (ctx) ->
      return if ctx.hbase_configured
      ctx.hbase_configured = true
      require('./core').configure ctx
      {static_host, realm} = ctx.config.hdp
      zookeeper_hosts = ctx.hosts_with_module('phyla/hadoop/zookeeper').join ','
      # User
      ctx.config.hdp.hbase_user = name: ctx.config.hdp.hbase_user if typeof ctx.config.hdp.hbase_user is 'string'
      ctx.config.hdp.hbase_user ?= {}
      ctx.config.hdp.hbase_user.name ?= 'hbase'
      ctx.config.hdp.hbase_user.system ?= true
      ctx.config.hdp.hbase_user.gid ?= 'hbase'
      ctx.config.hdp.hbase_user.comment ?= 'HBase User'
      ctx.config.hdp.hbase_user.home ?= '/var/run/hbase'
      # Group
      ctx.config.hdp.hbase_group = name: ctx.config.hdp.hbase_group if typeof ctx.config.hdp.hbase_group is 'string'
      ctx.config.hdp.hbase_group ?= {}
      ctx.config.hdp.hbase_group.name ?= 'hbase'
      ctx.config.hdp.hbase_group.system ?= true
      # Layout
      ctx.config.hdp.hbase_conf_dir ?= '/etc/hbase/conf'
      ctx.config.hdp.hbase_log_dir ?= '/var/log/hbase'
      ctx.config.hdp.hbase_pid_dir ?= '/var/run/hbase'
      ctx.config.hdp.hbase_site ?= {}
      # The mode the cluster will be in. Possible values are
      # false: standalone and pseudo-distributed setups with managed Zookeeper
      # true: fully-distributed with unmanaged Zookeeper Quorum (see hbase-env.sh)
      ctx.config.hdp.hbase_site['hbase.cluster.distributed'] = 'true'
      # Enter the HBase NameNode server hostname
      # http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/latest/CDH4-High-Availability-Guide/cdh4hag_topic_2_6.html
      ctx.config.hdp.hbase_site['hbase.rootdir'] ?= "hdfs://#{ctx.config.hdp.nameservice}:8020/apps/hbase/data"
      # ctx.config.hdp.hbase_site['hbase.rootdir'] ?= "hdfs://#{namenode}:8020/apps/hbase/data"
      # The bind address for the HBase Master web UI, [Official doc](http://hbase.apache.org/configuration.html)
      # Enter the HBase Master server hostname, [HDP DOC](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.6.0/bk_installing_manually_book/content/rpm-chap9-3.html)
      ctx.config.hdp.hbase_site['hbase.master.info.bindAddress'] ?= '0.0.0.0'
      # Comma separated list of Zookeeper servers (match to
      # what is specified in zoo.cfg but without portnumbers)
      ctx.config.hdp.hbase_site['hbase.zookeeper.quorum'] ?= "#{zookeeper_hosts}"
      ctx.config.hdp.hbase_site['hbase.master.keytab.file'] ?= '/etc/security/keytabs/hm.service.keytab'
      ctx.config.hdp.hbase_site['hbase.master.kerberos.principal'] ?= "hm/#{static_host}@#{realm}"
      ctx.config.hdp.hbase_site['hbase.regionserver.keytab.file'] ?= '/etc/security/keytabs/rs.service.keytab'
      ctx.config.hdp.hbase_site['hbase.regionserver.kerberos.principal'] ?= "rs/#{static_host}@#{realm}"
      ctx.config.hdp.hbase_site['hbase.superuser'] ?= 'hbase'
      ctx.config.hdp.hbase_site['hbase.coprocessor.region.classes'] ?= ''
      ctx.config.hdp.hbase_site['hbase.coprocessor.master.classes'] ?= ''
      # Short-circuit are true but socket.path isnt defined for hbase, only for hdfs, see http://osdir.com/ml/hbase-user-hadoop-apache/2013-03/msg00007.html
      ctx.config.hdp.hbase_site['dfs.domain.socket.path'] ?= '/var/lib/hadoop-hdfs/dn_socket'

## Users & Groups

By default, the "hbase" package create the following entries:

```bash
cat /etc/passwd | grep hbase
hbase:x:492:492:HBase:/var/run/hbase:/bin/bash
cat /etc/group | grep hbase
hbase:x:492:
```

    module.exports.push name: 'HDP HBase # Users & Groups', callback: (ctx, next) ->
      {hbase_group, hbase_user} = ctx.config.hdp
      ctx.group hbase_group, (err, gmodified) ->
        return next err if err
        ctx.user hbase_user, (err, umodified) ->
          next err, if gmodified or umodified then ctx.OK else ctx.PASS

## Install

Instructions to [install the HBase RPMs](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.2/bk_installing_manually_book/content/rpm-chap9-1.html)

    module.exports.push name: 'HDP HBase # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service name: 'hbase', (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP HBase # Layout', timeout: -1, callback: (ctx, next) ->
      {hadoop_group, hbase_user, hbase_pid_dir, hbase_log_dir} = ctx.config.hdp
      ctx.mkdir [
        destination: hbase_pid_dir
        uid: hbase_user.name
        gid: hadoop_group.name
        mode: '755'
      ,
        destination: hbase_log_dir
        uid: hbase_user.name
        gid: hadoop_group.name
        mode: '755'
      ], (err, modified) ->
        next err, if modified then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP HBase # Configure', callback: (ctx, next) ->
      {hbase_conf_dir, hbase_site} = ctx.config.hdp
      ctx.log 'Configure hbase-site.xml'
      ctx.hconfigure
        destination: "#{hbase_conf_dir}/hbase-site.xml"
        default: "#{__dirname}/files/hbase/hbase-site.xml"
        local_default: true
        properties: hbase_site
        merge: true
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP HBase # Env', callback: (ctx, next) ->
      {hbase_conf_dir, hbase_log_dir} = ctx.config.hdp
      ctx.log 'Write hbase-env.sh'
      ctx.upload
        source: "#{__dirname}/files/hbase/hbase-env.sh"
        destination: "#{hbase_conf_dir}/hbase-env.sh"
        write: [
          match: /^(export HBASE_LOG_DIR=).*$/mg
          replace: "$1#{hbase_log_dir}"
        ]
      , (err, uploaded) ->
        next err, if uploaded then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP HBase # RegionServers', callback: (ctx, next) ->
      {hbase_conf_dir, hbase_user, hadoop_group} = ctx.config.hdp
      regionservers = ctx.hosts_with_module('phyla/hadoop/hbase_regionserver').join '\n'
      ctx.write
        content: regionservers
        destination: "#{hbase_conf_dir}/regionservers"
        uid: hbase_user.name
        gid: hadoop_group.name
      , (err, written) ->
        next err, if written then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP HBase # Tuning', callback: (ctx, next) ->
      # http://hadoop-hbase.blogspot.fr/2014/03/hbase-gc-tuning-observations.html
      next null, ctx.TODO

## Resources

[HBase: Performance Tunners (read optimization)](http://labs.ericsson.com/blog/hbase-performance-tuners)
[Scanning in HBase (read optimization)](http://hadoop-hbase.blogspot.com/2012/01/scanning-in-hbase.html)
[Configuring HBase Memstore (write optimization)](http://blog.sematext.com/2012/17/16/hbase-memstore-what-you-should-know/)
[Visualizing HBase Flushes and Compactions (write optimization)](http://www.ngdata.com/visiualizing-hbase-flushes-and-compactions/)


