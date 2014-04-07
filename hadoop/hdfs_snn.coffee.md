---
title: 
layout: module
---

# HDFS SecondaryNameNode 

    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'phyla/hadoop/hdfs'

    module.exports.push (ctx) ->
      require('./hdfs').configure ctx

    module.exports.push name: 'HDP HDFS SNN # Directories', timeout: -1, callback: (ctx, next) ->
      {dfs_name_dir, fs_checkpoint_dir, hdfs_user, hadoop_group, hdfs_pid_dir} = ctx.config.hdp
      ctx.log "Create SNN data, checkpind and pid directories"
      ctx.mkdir [
        destination: dfs_name_dir
        uid: hdfs_user
        gid: hadoop_group
        mode: 0o755
      ,
        destination: fs_checkpoint_dir
        uid: hdfs_user
        gid: hadoop_group
        mode: 0o755
      ,
        destination: "#{hdfs_pid_dir}/#{hdfs_user}"
        uid: hdfs_user
        gid: hadoop_group
        mode: 0o755
      ], (err, created) ->
        next err, if created then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP HDFS SNN # Kerberos', callback: (ctx, next) ->
      {realm} = ctx.config.hdp
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