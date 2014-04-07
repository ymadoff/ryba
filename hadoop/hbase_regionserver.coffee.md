---
title: 
layout: module
---

# HBase RegionServer

    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'phyla/hadoop/hdfs'
    module.exports.push 'phyla/hadoop/zookeeper'
    module.exports.push 'phyla/hadoop/hbase'

    module.exports.push (ctx) ->
      require('./hdfs').configure
      require('./hbase').configure

    module.exports.push name: 'HDP HBase RegionServer # Kerberos', timeout: -1, callback: (ctx, next) ->
      {hadoop_group, hbase_user, hbase_site, realm} = ctx.config.hdp
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: hbase_site['hbase.regionserver.kerberos.principal'].replace '_HOST', ctx.config.host
        randkey: true
        keytab: hbase_site['hbase.regionserver.keytab.file']
        uid: hbase_user
        gid: hadoop_group
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , (err, created) ->
        next err, if created then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP HBase RegionServer # Start', callback: (ctx, next) ->
      lifecycle.hbase_regionserver_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS
