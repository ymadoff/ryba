---
title: 
layout: module
---

# HBase RegionServer

    lifecycle = require '../hadoop/lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hadoop/hdfs'
    module.exports.push 'ryba/hbase/_'

    module.exports.push module.exports.configure = (ctx) ->
      require('../hadoop/hdfs').configure ctx
      require('./_').configure ctx

    module.exports.push name: 'HBase RegionServer # Service', timeout: -1, callback: (ctx, next) ->
      ctx.service 
        name: 'hbase-regionserver'
      , (err, installed) ->
        next err, if installed then ctx.OK else ctx.PASS

## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master, 
RegionServer, and HBase client host machines.

    module.exports.push name: 'HBase RegionServer # Zookeeper JAAS', timeout: -1, callback: (ctx, next) ->
      {jaas_server, hbase_conf_dir, hbase_user, hbase_group} = ctx.config.hdp
      ctx.write
        destination: "#{hbase_conf_dir}/hbase-regionserver.jaas"
        content: jaas_server
        uid: hbase_user.name
        gid: hbase_group.name
        mode: 0o700
      , (err, written) ->
        return next err, if written then ctx.OK else ctx.PASS

    module.exports.push name: 'HBase RegionServer # Kerberos', timeout: -1, callback: (ctx, next) ->
      {hadoop_group, hbase_user, hbase_site, realm} = ctx.config.hdp
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
      {hbase_site, hbase_user, hbase_group, hadoop_group} = ctx.config.hdp
      {hdfs_site} = ctx.config.hdp
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
      {hbase_conf_dir} = ctx.config.hdp
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




