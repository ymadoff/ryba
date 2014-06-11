---
title: 
layout: module
---

# HBase Master

    lifecycle = require './lib/lifecycle'
    mkcmd = require './lib/mkcmd'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'phyla/hadoop/hdfs'
    # module.exports.push 'phyla/hadoop/zookeeper'
    module.exports.push 'phyla/hadoop/hbase'

    module.exports.push (ctx) ->
      require('./hdfs').configure ctx
      require('./hbase').configure ctx

    module.exports.push name: 'HDP HBase Master # HDFS layout', callback: (ctx, next) ->
      {hbase_user} = ctx.config.hdp
      ctx.log "Create /apps/hbase"
      ctx.execute
        cmd: mkcmd.hdfs ctx, """
        if hdfs dfs -ls /apps/hbase &>/dev/null; then exit 3; fi
        hdfs dfs -mkdir -p /apps/hbase
        hdfs dfs -chown -R #{hbase_user.name} /apps/hbase
        """
        code_skipped: 3
      , (err, executed, stdout) ->
        next err, if executed then ctx.OK else ctx.PASS

https://blogs.apache.org/hbase/entry/hbase_cell_security
https://hbase.apache.org/book/security.html

    module.exports.push name: 'HDP HBase Master # Kerberos', callback: (ctx, next) ->
      {hadoop_group, hbase_user, hbase_site, realm} = ctx.config.hdp
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: hbase_site['hbase.master.kerberos.principal'].replace '_HOST', ctx.config.host
        randkey: true
        keytab: hbase_site['hbase.master.keytab.file']
        uid: hbase_user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , (err, created) ->
        next err, if created then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP HBase Master # Start', callback: (ctx, next) ->
      lifecycle.hbase_master_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS




