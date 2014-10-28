---
title: HDFS DataNode
module: ryba/hadoop/hdfs_dn
layout: module
---

# HDFS DataNode Install

A DataNode manages the storage attached to the node it run on. There 
are usually one DataNode per node in the cluster. HDFS exposes a file 
system namespace and allows user data to be stored in files. Internally, 
a file is split into one or more blocks and these blocks are stored in 
a set of DataNodes. The DataNodes also perform block creation, deletion, 
and replication upon instruction from the NameNode.

In a Hight Availabity (HA) enrironment, in order to provide a fast 
failover, it is necessary that the Standby node have up-to-date 
information regarding the location of blocks in the cluster. In order 
to achieve this, the DataNodes are configured with the location of both 
NameNodes, and send block location information and heartbeats to both.

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs'
    module.exports.push require('./hdfs_dn').configure

## IPTables

| Service   | Port       | Proto     | Parameter                  |
|-----------|------------|-----------|----------------------------|
| datanode  | 50010/1004 | tcp/http  | dfs.datanode.address       |
| datanode  | 50075/1006 | tcp/http  | dfs.datanode.http.address  |
| datanode  | 50475      | tcp/https | dfs.datanode.https.address |
| datanode  | 50020      | tcp       | dfs.datanode.ipc.address   |

The "dfs.datanode.address" default to "50010" in non-secured mode. In non-secured
mode, it must be set to a value below "1024" and default to "1004".

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'Hadoop HDFS DN # IPTables', callback: (ctx, next) ->
      {hdfs_site} = ctx.config.ryba
      [_, dn_address] = hdfs_site['dfs.datanode.address'].split ':'
      [_, dn_http_address] = hdfs_site['dfs.datanode.http.address'].split ':'
      [_, dn_https_address] = hdfs_site['dfs.datanode.https.address'].split ':'
      [_, dn_ipc_address] = hdfs_site['dfs.datanode.ipc.address'].split ':'
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: dn_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN Data" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: dn_http_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: dn_https_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN HTTPS" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: dn_ipc_address, protocol: 'tcp', state: 'NEW', comment: "HDFS DN Meta" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Startup

Install and configure the startup script in 
"/etc/init.d/hadoop-yarn-nodemanager".

    module.exports.push name: 'Hadoop HDFS DN # Startup', callback: (ctx, next) ->
      {hdfs_pid_dir, core_site} = ctx.config.ryba
      modified = false
      do_install = ->
        ctx.service
          name: 'hadoop-hdfs-datanode'
          startup: true
        , (err, serviced) ->
          return next err if err
          modified = true if serviced
          do_fix()
      do_fix = ->
        user = if core_site['hadoop.security.authentication'] is 'kerberos' then 'hdfs' else ''
        ctx.write
          destination: '/etc/init.d/hadoop-hdfs-datanode'
          write: [
            match: /^PIDFILE=".*"$/m
            replace: "PIDFILE=\"#{hdfs_pid_dir}/$SVC_USER/hadoop-hdfs-datanode.pid\""
          ,
            match: /^HADOOP_SECURE_DN_USER=".*"$/m
            replace: "HADOOP_SECURE_DN_USER=\"#{user}\""
            append: /^WORKING_DIR=.*$/m
          ]
        , (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        next null, modified
      do_install()

## HA

Update the "hdfs_site.xml" configuration file with the High Availabity properties
present inside the "hdp.ha\_client\_config" object.

    module.exports.push name: 'Hadoop HDFS DN # HA', callback: (ctx, next) ->
      return next() if ctx.host_with_module 'ryba/hadoop/hdfs_snn'
      {hadoop_conf_dir, ha_client_config} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        properties: ha_client_config
        merge: true
      , next

## Layout

Create the DataNode data and pid directories. The data directory is set by the 
"hdp.hdfs_site['dfs.datanode.data.dir']" and default to "/var/hdfs/data". The 
pid directory is set by the "hdfs\_pid\_dir" and default to "/var/run/hadoop-hdfs"

    module.exports.push name: 'Hadoop HDFS DN # Layout', timeout: -1, callback: (ctx, next) ->
      {hdfs_site, hdfs_user, hadoop_group, hdfs_pid_dir} = ctx.config.ryba
      # no need to restrict parent directory and yarn will complain if not accessible by everyone
      ctx.mkdir [
        destination: hdfs_site['dfs.datanode.data.dir'].split ','
        uid: hdfs_user.name
        gid: hadoop_group.name
        mode: 0o0750
      ,
        destination: "#{hdfs_pid_dir}/#{hdfs_user}"
        uid: hdfs_user.name
        gid: hadoop_group.name
        mode: 0o0755
      ], next

## Kerberos

Create the DataNode service principal in the form of "dn/{host}@{realm}" and place its
keytab inside "/etc/security/keytabs/dn.service.keytab" with ownerships set to "hdfs:hadoop"
and permissions set to "0600".

    module.exports.push name: 'Hadoop HDFS DN # Kerberos', timeout: -1, callback: (ctx, next) ->
      {hdfs_user, hdfs_group, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc 
        principal: "dn/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/dn.service.keytab"
        uid: hdfs_user.name
        gid: hdfs_group.name
        mode: 0o0600
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next

## DataNode Start

Load the module "ryba/hadoop/hdfs\_dn\_start" to start the DataNode.

    module.exports.push 'ryba/hadoop/hdfs_dn_start'

## HDFS layout

Set up the directories and permissions inside the HDFS filesytem. The layout is inspired by the
[Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)
on the official Apache website. The following folder are created:

```
drwxr-xr-x   - hdfs   hadoop      /
drwxr-xr-x   - hdfs   hadoop      /apps
drwxrwxrwt   - hdfs   hadoop      /tmp
drwxr-xr-x   - hdfs   hadoop      /user
drwxr-xr-x   - hdfs   hadoop      /user/hdfs
```

    module.exports.push name: 'Hadoop HDFS DN # HDFS layout', timeout: -1, callback: (ctx, next) ->
      {hadoop_group, hdfs_user} = ctx.config.ryba
      modified = false
      do_wait = ->
        ctx.waitForExecution mkcmd.hdfs(ctx, "hdfs dfs -test -d /"), (err) ->
          return next err if err
          do_root()
      do_root = ->
        ctx.execute
          cmd: mkcmd.hdfs ctx, """
          hdfs dfs -chmod 755 /
          """
        , (err, executed, stdout) ->
          return next err if err
          do_tmp()
      do_tmp = ->
        ctx.execute
          cmd: mkcmd.hdfs ctx, """
          if hdfs dfs -test -d /tmp; then exit 2; fi
          hdfs dfs -mkdir /tmp
          hdfs dfs -chown #{hdfs_user.name}:#{hadoop_group.name} /tmp
          hdfs dfs -chmod 1777 /tmp
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          return next err if err
          ctx.log 'Directory "/tmp" prepared' and modified = true if executed
          do_user()
      do_user = ->
        ctx.execute
          cmd: mkcmd.hdfs ctx, """
          if hdfs dfs -test -d /user; then exit 2; fi
          hdfs dfs -mkdir /user
          hdfs dfs -chown #{hdfs_user.name}:#{hadoop_group.name} /user
          hdfs dfs -chmod 755 /user
          hdfs dfs -mkdir /user/#{hdfs_user.name}
          hdfs dfs -chown #{hdfs_user.name}:#{hadoop_group.name} /user/#{hdfs_user.name}
          hdfs dfs -chmod 755 /user/#{hdfs_user.name}
          """
          # hdfs dfs -mkdir /user/#{test_user.name}
          # hdfs dfs -chown #{test_user.name}:#{hadoop_group.name} /user/#{test_user.name}
          # hdfs dfs -chmod 755 /user/#{test_user.name}
          code_skipped: 2
        , (err, executed, stdout) ->
          return next err if err
          ctx.log 'Directory "/user" prepared' and modified = true if executed
          do_apps()
      do_apps = ->
        ctx.execute
          cmd: mkcmd.hdfs ctx, """
          if hdfs dfs -test -d /apps; then exit 2; fi
          hdfs dfs -mkdir /apps
          hdfs dfs -chown #{hdfs_user.name}:#{hadoop_group.name} /apps
          hdfs dfs -chmod 755 /apps
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          return next err if err
          ctx.log 'Directory "/apps" prepared' and modified = true if executed
          do_end()
      do_end = ->
        next null, modified
      do_wait()

## Test User

Create a Unix and Kerberos test user, by default "test" and execute simple HDFS commands to ensure
the NameNode is properly working. Note, those commands are NameNode specific, meaning they only
afect HDFS metadata.

    module.exports.push name: 'Hadoop HDFS DN # Test User', timeout: -1, callback: (ctx, next) ->
      {test_group, test_user, test_password, security, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      modified = false
      do_user_unix = ->
        # ryba group and user may already exist in "/etc/passwd" or in any sssd backend
        ctx.group test_group, (err, gmodified) ->
          return next err if err
          ctx.user test_user, (err, umodified) ->
            return next err if err
            modified = true if gmodified or umodified
            do_user_krb5()
      do_user_krb5 = ->
        ctx.krb5_addprinc
          principal: "#{test_user.name}@#{realm}"
          password: "#{test_password}"
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: admin_server
        , (err, created) ->
          return next err if err
          modified = true if created
          do_hdfs()
      do_hdfs = ->
        # Carefull, this is a dupplicate of
        # "HDP HDFS DN # HDFS layout"
        ctx.execute
          cmd: mkcmd.hdfs ctx, """
          if hdfs dfs -test -d /user/#{test_user.name}; then exit 2; fi
          hdfs dfs -mkdir /user/#{test_user.name}
          hdfs dfs -chown #{test_user.name}:#{test_group.name} /user/#{test_user.name}
          hdfs dfs -chmod 750 /user/#{test_user.name}
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          modified = true if executed
          next err, modified
      do_user_unix()

    module.exports.push 'ryba/hadoop/hdfs_dn_check'

## Module dependencies

    path = require 'path'
    hdfs_nn = require './hdfs_nn'
    lifecycle = require '../lib/lifecycle'
    mkcmd = require '../lib/mkcmd'



