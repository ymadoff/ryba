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
      {hdfs_site, static_host, realm} = ctx.config.ryba
      # Store the temporary images to merge
      hdfs_site['dfs.namenode.checkpoint.dir'] ?= ['/var/hdfs/checkpoint']
      hdfs_site['dfs.namenode.checkpoint.dir'] = hdfs_site['dfs.namenode.checkpoint.dir'].join ',' if Array.isArray hdfs_site['dfs.namenode.checkpoint.dir']
      # Kerberos principal name for the secondary NameNode.
      hdfs_site['dfs.secondary.namenode.kerberos.principal'] ?= "nn/#{static_host}@#{realm}"
      # Combined keytab file containing the NameNode service and host principals.
      hdfs_site['dfs.secondary.namenode.keytab.file'] ?= '/etc/security/keytabs/nn.service.keytab'
      # Address of secondary namenode web server
      hdfs_site['dfs.secondary.http.address'] ?= "#{ctx.config.host}:50090"
      # The https port where secondary-namenode binds
      hdfs_site['dfs.secondary.https.port'] ?= '50490' # todo, this has nothing to do here
      hdfs_site['dfs.namenode.secondary.http-address'] ?= "#{ctx.config.host}:50090" # HDS > 2.5.1
      hdfs_site['dfs.namenode.secondary.https-address'] ?= "#{ctx.config.host}:50490" # HDS > 2.5.1
      hdfs_site['dfs.secondary.namenode.kerberos.internal.spnego.principal'] ?= "HTTP/#{static_host}@#{realm}"
      hdfs_site['dfs.secondary.namenode.kerberos.https.principal'] = "host/#{static_host}@#{realm}"

## IPTables

| Service    | Port | Proto  | Parameter                  |
|------------|------|--------|----------------------------|
| namenode  | 50070 | tcp    | dfs.namdnode.http-address  |
| namenode  | 50470 | tcp    | dfs.namenode.https-address |
| namenode  | 8020  | tcp    | fs.defaultFS               |
| namenode  | 8019  | tcp    | dfs.ha.zkfc.port           |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'HDP HDFS SNN # IPTables', callback: (ctx, next) ->
      {hdfs_site} = ctx.config.ryba
      [_, http_port] = hdfs_site['dfs.namenode.secondary.http-address'].split ':'
      [_, https_port] = hdfs_site['dfs.namenode.secondary.https-address'].split ':'
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: http_port, protocol: 'tcp', state: 'NEW', comment: "HDFS SNN HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: https_port, protocol: 'tcp', state: 'NEW', comment: "HDFS SNN HTTPS" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

    module.exports.push name: 'HDP HDFS SNN # Directories', timeout: -1, callback: (ctx, next) ->
      {hdfs_pid_dir} = ctx.config.ryba
      ctx.service
        name: 'hadoop-hdfs-secondarynamenode'
        startup: true
      , (err, serviced) ->
        return next err if err
        ctx.write
          destination: '/etc/init.d/hadoop-hdfs-secondarynamenode'
          write: [
            {match: /^PIDFILE=".*"$/m, replace: "PIDFILE=\"#{hdfs_pid_dir}/$SVC_USER/hadoop-hdfs-secondarynamenode.pid\""}
            {match: /^(\s+start_daemon)\s+(\$EXEC_PATH.*)$/m, replace: "$1 -u $SVC_USER $2"}]
        , (err, written) ->
          next err, serviced or written

    module.exports.push name: 'HDP HDFS SNN # Directories', timeout: -1, callback: (ctx, next) ->
      {hdfs_site, hdfs_user, hadoop_group, hdfs_pid_dir} = ctx.config.ryba
      ctx.log "Create SNN data, checkpind and pid directories"
      ctx.mkdir [
        destination: hdfs_site['dfs.namenode.checkpoint.dir'].split ','
        uid: hdfs_user.name
        gid: hadoop_group.name
        mode: 0o755
      ,
        destination: "#{hdfs_pid_dir}/#{hdfs_user.name}"
        uid: hdfs_user.name
        gid: hadoop_group.name
        mode: 0o755
      ], next

    module.exports.push name: 'HDP HDFS SNN # Kerberos', callback: (ctx, next) ->
      {realm, hdfs_site} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc 
        principal: "nn/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: hdfs_site['dfs.secondary.namenode.keytab.file']
        uid: 'hdfs'
        gid: 'hadoop'
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next

# Configure

    module.exports.push name: 'HDP HDFS SNN # Configure', callback: (ctx, next) ->
      {hadoop_conf_dir, hdfs_user, hadoop_group, hdfs_site} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        properties: hdfs_site
        uid: hdfs_user
        gid: hadoop_group
        merge: true
      , next

    module.exports.push 'ryba/hadoop/hdfs_snn'




