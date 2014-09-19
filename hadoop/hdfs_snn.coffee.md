---
title: 
layout: module
---

# HDFS SecondaryNameNode 

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hadoop/hdfs'

    module.exports.push (ctx) ->
      require('./hdfs').configure ctx
      {hdfs_site} = ctx.config.ryba
      # Kerberos principal name for the secondary NameNode.
      hdfs_site['dfs.secondary.namenode.kerberos.principal'] ?= "nn/#{static_host}@#{realm}"
      # Address of secondary namenode web server
      hdfs_site['dfs.secondary.http.address'] ?= "#{secondary_namenode}:50090"
      # The https port where secondary-namenode binds
      hdfs_site['dfs.secondary.https.port'] ?= '50490' # todo, this has nothing to do here
      # Combined keytab file containing the NameNode service and host principals.
      hdfs_site['dfs.secondary.namenode.keytab.file'] ?= '/etc/security/keytabs/nn.service.keytab'
      hdfs_site['dfs.secondary.namenode.kerberos.internal.spnego.principal'] ?= "HTTP/#{static_host}@#{realm}"
      hdfs_site['dfs.secondary.namenode.kerberos.https.principal'] = "host/#{static_host}@#{realm}"

    module.exports.push name: 'HDP HDFS SNN # Directories', timeout: -1, callback: (ctx, next) ->
      {hdfs_site, fs_checkpoint_dir, hdfs_user, hadoop_group, hdfs_pid_dir} = ctx.config.ryba
      ctx.log "Create SNN data, checkpind and pid directories"
      ctx.mkdir [
        destination: hdfs_site['dfs.namenode.name.dir']
        uid: hdfs_user.name
        gid: hadoop_group.name
        mode: 0o755
      ,
        destination: fs_checkpoint_dir
        uid: hdfs_user.name
        gid: hadoop_group.name
        mode: 0o755
      ,
        destination: "#{hdfs_pid_dir}/#{hdfs_user.name}"
        uid: hdfs_user.name
        gid: hadoop_group.name
        mode: 0o755
      ], (err, created) ->
        next err, if created then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP HDFS SNN # Kerberos', callback: (ctx, next) ->
      {realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc 
        principal: "nn/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/nn.service.keytab"
        uid: 'hdfs'
        gid: 'hadoop'
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , (err, created) ->
        next err, if created then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP HDFS SNN # Start', callback: (ctx, next) ->
      lifecycle.snn_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS




