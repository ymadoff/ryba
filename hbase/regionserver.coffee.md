---
title: 
layout: module
---

# HBase RegionServer

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs'
    module.exports.push 'ryba/hbase/_'

    module.exports.push module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('../hadoop/hdfs').configure ctx
      require('./_').configure ctx

## IPTables

| Service                      | Port  | Proto | Info                         |
|------------------------------|-------|-------|------------------------------|
| HBase Region Server          | 60020 | http  | hbase.regionserver.port      |
| HMaster Region Server Web UI | 60030 | http  | hbase.regionserver.info.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'HDP RegionServer # IPTables', callback: (ctx, next) ->
      {hbase_site} = ctx.config.ryba
      port = 
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase_site['hbase.regionserver.port'] or 60020, protocol: 'tcp', state: 'NEW', comment: "HBase Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase_site['hbase.regionserver.info.port'] or 60030, protocol: 'tcp', state: 'NEW', comment: "HMaster Info Web UI" }
        ]
        if: ctx.config.iptables.action is 'start'
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

## Service

Install and configure the startup script in 
"/etc/init.d/hbase-regionserver".

    module.exports.push name: 'HBase RegionServer # Startup', timeout: -1, callback: (ctx, next) ->
      modified = false
      do_install = ->
        ctx.service 
          name: 'hbase-regionserver'
        , (err, serviced) ->
          return next err if err
          modified = true if serviced
          do_write()
      do_write = ->
        ctx.write
          destination: '/etc/init.d/hbase-regionserver'
          match: /^\s+exit 3 # Ryba: Fix invalid exit code*$/m
          replace: '            exit 3 # Ryba: Fix invalid exit code'
          append: /^\s+echo "not running."$/m
        , (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        next null, if modified then ctx.OK else ctx.PASS
      do_install()

## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master, 
RegionServer, and HBase client host machines.

    module.exports.push name: 'HBase RegionServer # Zookeeper JAAS', timeout: -1, callback: (ctx, next) ->
      {jaas_server, hbase_conf_dir, hbase_user, hbase_group} = ctx.config.ryba
      ctx.write
        destination: "#{hbase_conf_dir}/hbase-regionserver.jaas"
        content: jaas_server
        uid: hbase_user.name
        gid: hbase_group.name
        mode: 0o700
      , (err, written) ->
        return next err, if written then ctx.OK else ctx.PASS

    module.exports.push name: 'HBase RegionServer # Kerberos', timeout: -1, callback: (ctx, next) ->
      {hadoop_group, hbase_user, hbase_site, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: hbase_site['hbase.regionserver.kerberos.principal'].replace '_HOST', ctx.config.host
        randkey: true
        keytab: hbase_site['hbase.regionserver.keytab.file']
        uid: hbase_user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , (err, created) ->
        next err, if created then ctx.OK else ctx.PASS

## SPNEGO

Check if keytab file exists and if read permission is granted to the HBase user.

Note: The Namenode webapp located in "/usr/lib/hbase/hbase-webapps/regionserver" is
using the hadoop conf directory to retrieve the SPNEGO keytab. The user "hbase"
is added membership to the group hadoop to gain read access.

    module.exports.push name: 'HBase RegionServer # FIX SPNEGO', callback: (ctx, next) ->
      {hbase_site, hbase_user, hbase_group, hadoop_group} = ctx.config.ryba
      {hdfs_site} = ctx.config.ryba
      ctx.execute
        cmd: """
          if groups #{hbase_user.name} | grep #{hadoop_group.name}; then exit 2; fi
          usermod -G #{hadoop_group.name} #{hbase_user.name}
        """
        code_skipped: 2
      , (err, modified) ->
        return next err if err
        ctx.execute
          cmd: "su -l #{hbase_user.name} -c 'test -r /etc/security/keytabs/spnego.service.keytab'"
        , (err) ->
          next err, if modified then ctx.OK else ctx.PASS
      # ctx.copy [
      #   source: '/etc/security/keytabs/spnego.service.keytab'
      #   destination: hbase_site['hbase.thrift.keytab.file']
      #   uid: hbase_user.name
      #   gid: hbase_group.name
      #   mode: 0o660
      # ,
      #   source: '/etc/security/keytabs/spnego.service.keytab'
      #   destination: hbase_site['hbase.rest.authentication.kerberos.keytab']
      #   uid: hbase_user.name
      #   gid: hbase_group.name
      #   mode: 0o660
      
      # ], (err, copied) ->
      #   return next err, if copied then ctx.OK else ctx.PASS

## Metrics

Enable stats collection in Ganglia.

    module.exports.push name: 'HBase RegionServer # Metrics', callback: (ctx, next) ->
      {hbase_conf_dir} = ctx.config.ryba
      collector = ctx.host_with_module 'ryba/hadoop/ganglia_collector'
      return next() unless collector
      ctx.upload
        source: "#{__dirname}/../hadoop/files/hbase/hadoop-metrics.properties.regionservers-GANGLIA"
        destination: "#{hbase_conf_dir}/hadoop-metrics.properties"
        match: 'TODO-GANGLIA-SERVER'
        replace: collector
      , (err, uploaded) ->
        next err, if uploaded then ctx.OK else ctx.PASS

    module.exports.push name: 'HBase RegionServer # Start', callback: (ctx, next) ->
      lifecycle.hbase_regionserver_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS




