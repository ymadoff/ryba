---
title: HDFS DataNode
module: phyla/hadoop/hdfs_dn
layout: module
---

# HDFS DataNode

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

    path = require 'path'
    hdfs_nn = require './hdfs_nn'
    lifecycle = require './lib/lifecycle'
    mkcmd = require './lib/mkcmd'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'phyla/hadoop/hdfs'

## Configuration

The module doesn't require any configuration but instread rely on the 
"phyla/hadoop/hdfs" configuration settings.

    module.exports.push (ctx) ->
      require('./hdfs').configure ctx
## HA

Update the "hdfs_site.xml" configuration file with the High Availabity properties
present inside the "hdp.ha\_client\_config" object.

    module.exports.push name: 'HDP HDFS DN # HA', callback: (ctx, next) ->
      {hadoop_conf_dir, ha_client_config} = ctx.config.hdp
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        properties: ha_client_config
        merge: true
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

## Layout

Create the DataNode data and pid directories. The data directory is set by the 
"hdp.hdfs_site['dfs.datanode.data.dir']" and default to "/hadoop/hdfs/data". The 
pid directory is set by the "hdfs\_pid\_dir" and default to "/var/run/hadoop-hdfs"

    module.exports.push name: 'HDP HDFS DN # Layout', timeout: -1, callback: (ctx, next) ->
      {hdfs_site, hdfs_user, hadoop_group, hdfs_pid_dir} = ctx.config.hdp
      # no need to restrict parent directory and yarn will complain if not accessible by everyone
      ctx.mkdir [
        destination: hdfs_site['dfs.datanode.data.dir'].split ','
        uid: hdfs_user
        gid: hadoop_group
        mode: 0o0750
      ,
        destination: "#{hdfs_pid_dir}/#{hdfs_user}"
        uid: hdfs_user
        gid: hadoop_group
        mode: 0o0755
      ], (err, created) ->
        next err, if created then ctx.OK else ctx.PASS

## Kerberos

Create the DataNode service principal in the form of "dn/{host}@{realm}" and place its
keytab inside "/etc/security/keytabs/dn.service.keytab" with ownerships set to "hdfs:hadoop"
and permissions set to "0600".

    module.exports.push name: 'HDP HDFS DN # Kerberos', timeout: -1, callback: (ctx, next) ->
      {hdfs_user, hdfs_group, realm} = ctx.config.hdp
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc 
        principal: "dn/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/dn.service.keytab"
        uid: hdfs_user
        gid: hdfs_group
        mode: 0o0600
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , (err, created) ->
        next err, if created then ctx.OK else ctx.PASS

## DataNode Start

Load the module "phyla/hadoop/hdfs\_dn\_start" to start the DataNode.

    module.exports.push 'phyla/hadoop/hdfs_dn_start'

    # module.exports.push name: 'HDP HDFS DN # Start', timeout: -1, callback: (ctx, next) ->
    #   namenodes = ctx.hosts_with_module 'phyla/hadoop/hdfs_nn'
    #   ctx.waitIsOpen namenodes, 50070, (err) ->
    #     lifecycle.dn_start ctx, (err, started) ->
    #       next err, ctx.OK

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

    module.exports.push name: 'HDP HDFS DN # HDFS layout', timeout: -1, callback: (ctx, next) ->
      {hadoop_group, hdfs_user, yarn, yarn_user} = ctx.config.hdp
      # test_user, 
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
          if hdfs dfs -test -d /tmp; then exit 1; fi
          hdfs dfs -mkdir /tmp
          hdfs dfs -chown #{hdfs_user}:#{hadoop_group} /tmp
          hdfs dfs -chmod 1777 /tmp
          """
          code_skipped: 1
        , (err, executed, stdout) ->
          return next err if err
          ctx.log 'Directory "/tmp" prepared' and modified = true if executed
          do_user()
      do_user = ->
        ctx.execute
          cmd: mkcmd.hdfs ctx, """
          if hdfs dfs -test -d /user; then exit 1; fi
          hdfs dfs -mkdir /user
          hdfs dfs -chown #{hdfs_user}:#{hadoop_group} /user
          hdfs dfs -chmod 755 /user
          hdfs dfs -mkdir /user/#{hdfs_user}
          hdfs dfs -chown #{hdfs_user}:#{hadoop_group} /user/#{hdfs_user}
          hdfs dfs -chmod 755 /user/#{hdfs_user}
          """
          # hdfs dfs -mkdir /user/#{test_user}
          # hdfs dfs -chown #{test_user}:#{hadoop_group} /user/#{test_user}
          # hdfs dfs -chmod 755 /user/#{test_user}
          code_skipped: 1
        , (err, executed, stdout) ->
          return next err if err
          ctx.log 'Directory "/user" prepared' and modified = true if executed
          do_apps()
      do_apps = ->
        ctx.execute
          cmd: mkcmd.hdfs ctx, """
          if hdfs dfs -test -d /apps; then exit 1; fi
          hdfs dfs -mkdir /apps
          hdfs dfs -chown #{hdfs_user}:#{hadoop_group} /apps
          hdfs dfs -chmod 755 /apps
          """
          code_skipped: 1
        , (err, executed, stdout) ->
          return next err if err
          ctx.log 'Directory "/apps" prepared' and modified = true if executed
          do_end()
      do_end = ->
        next null, if modified then ctx.OK else ctx.PASS
      do_wait()

## Test User

Create a Unix and Kerberos test user, by default "test" and execute simple HDFS commands to ensure
the NameNode is properly working. Note, those commands are NameNode specific, meaning they only
afect HDFS metadata.

    module.exports.push name: 'HDP HDFS NN # Test User', timeout: -1, callback: (ctx, next) ->
      {hdfs_user, test_user, test_password, hadoop_group, security, realm} = ctx.config.hdp
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      modified = false
      do_user = ->
        if security is 'kerberos'
        then do_user_krb5()
        else do_user_unix()
      do_user_unix = ->
        ctx.execute
          cmd: "useradd #{test_user} -r -M -g #{hadoop_group} -s /bin/bash -c \"Used by Hadoop to test\""
          code: 0
          code_skipped: 9
        , (err, created) ->
          return next err if err
          modified = true if created
          do_run()
      do_user_krb5 = ->
        ctx.krb5_addprinc
          principal: "#{test_user}@#{realm}"
          password: "#{test_password}"
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: admin_server
        , (err, created) ->
          return next err if err
          modified = true if created
          do_run()
      do_run = ->
        # Carefull, this is a dupplicate of
        # "HDP HDFS DN # HDFS layout"
        ctx.execute
          cmd: mkcmd.hdfs ctx, """
          if hdfs dfs -test -d /user/#{test_user}; then exit 2; fi
          hdfs dfs -mkdir /user/#{test_user}
          hdfs dfs -chown #{test_user}:#{hadoop_group} /user/#{test_user}
          hdfs dfs -chmod 755 /user/#{test_user}
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          modified = true if executed
          next err, if modified then ctx.OK else ctx.PASS
      do_user()

## Test HDFS

Attemp to put a file into HDFS. the file "/etc/passwd" will be placed at 
"/user/{test\_user}/#{ctx.config.host}\_dn".

    module.exports.push name: 'HDP HDFS DN # Test HDFS', timeout: -1, callback: (ctx, next) ->
      {test_user} = ctx.config.hdp
      ctx.execute
        cmd: mkcmd.test ctx, """
        if hdfs dfs -test -f /user/#{test_user}/#{ctx.config.host}-dn; then exit 2; fi
        echo 'Upload file to HDFS'
        hdfs dfs -put /etc/passwd /user/#{test_user}/#{ctx.config.host}-dn
        """
        code_skipped: 2
      , (err, executed, stdout, stderr) ->
        next err, if executed then ctx.OK else ctx.PASS

## Test WebHDFS

Test the Kerberos SPNEGO and the Hadoop delegation token. Will only be 
executed if the file "/user/{test\_user}/{host}\_webhdfs" generated by this action 
is not present on HDFS.

Read [Delegation Tokens in Hadoop Security](http://www.kodkast.com/blogs/hadoop/delegation-tokens-in-hadoop-security) 
for more information.

    module.exports.push name: 'HDP HDFS DN # Test WebHDFS', timeout: -1, callback: (ctx, next) ->
      {test_user, force_check, active_nn_host} = ctx.config.hdp
      do_init = ->
        ctx.execute
          cmd: mkcmd.test ctx, """
          if hdfs dfs -test -f /user/#{test_user}/#{ctx.config.host}-webhdfs; then exit 2; fi
          hdfs dfs -touchz /user/#{test_user}/#{ctx.config.host}-webhdfs
          kdestroy
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          return next err if err
          return do_spnego() if force_check
          return next null, ctx.PASS unless executed
          do_spnego()
      do_spnego = ->
        ctx.execute
          cmd: mkcmd.test ctx, """
          curl -s --negotiate -u : "http://#{active_nn_host}:50070/webhdfs/v1/user/#{test_user}?op=LISTSTATUS"
          kdestroy
          """
        , (err, executed, stdout) ->
          return next err if err
          count = JSON.parse(stdout).FileStatuses.FileStatus.filter((e) -> e.pathSuffix is "#{ctx.config.host}-webhdfs").length
          return next null, ctx.FAILED unless count
          do_token()
      do_token = ->
        ctx.execute
          cmd: mkcmd.test ctx, """
          curl -s --negotiate -u : "http://#{active_nn_host}:50070/webhdfs/v1/?op=GETDELEGATIONTOKEN"
          kdestroy
          """
        , (err, executed, stdout) ->
          return next err if err
          token = JSON.parse(stdout).Token.urlString
          ctx.execute
            cmd: """
            curl -s "http://#{active_nn_host}:50070/webhdfs/v1/user/#{test_user}?delegation=#{token}&op=LISTSTATUS"
            """
          , (err, executed, stdout) ->
            return next err if err
            count = JSON.parse(stdout).FileStatuses.FileStatus.filter((e) -> e.pathSuffix is "#{ctx.config.host}-webhdfs").length
            return next null, ctx.FAILED unless count
            do_end()
      do_end = ->
        next null, ctx.OK
      do_init()






