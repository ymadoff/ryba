---
title: 
layout: module
---

# MapRed JobHistoryServer

    lifecycle = require './lib/lifecycle'
    mkcmd = require './lib/mkcmd'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/mapred'

    module.exports.push (ctx) ->
      require('masson/core/iptables').configure ctx
      require('./mapred').configure ctx
      ctx.config.hdp.mapred['mapreduce.jobhistory.keytab'] ?= "/etc/security/keytabs/jhs.service.keytab"
      # Fix: src in "[DFSConfigKeys.java][keys]" and [HDP port list] mention 13562
      # while companion files mentions 8081
      ctx.config.hdp.mapred['mapreduce.shuffle.port'] ?= '13562'

## IPTables

| Service          | Port  | Proto | Parameter                     |
|------------------|-------|-------|-------------------------------|
| jobhistory | 10020 | http  | mapreduce.jobhistory.address        | x
| jobhistory | 19888 | tcp   | mapreduce.jobhistory.webapp.address | x
| jobhistory | 13562 | tcp   | mapreduce.shuffle.port              | x
| jobhistory | 10033 | tcp   | mapreduce.jobhistory.admin.address  |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'HDP MapRed JHS # IPTables', callback: (ctx, next) ->
      {mapred} = ctx.config.hdp
      shuffle = mapred['mapreduce.shuffle.port']
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 10020, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS Server" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 19888, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS WebApp" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: shuffle, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS Shuffle" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 10033, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS Admin Server" }
        ]
        if: ctx.config.iptables.action is 'start'
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

## Startup

Install and configure the startup script in 
"/etc/init.d/hadoop-mapreduce-historyserver".

    module.exports.push name: 'HDP HDFS JN # Startup', callback: (ctx, next) ->
      {mapred_pid_dir} = ctx.config.hdp
      modified = false
      do_install = ->
        ctx.service
          name: 'hadoop-mapreduce-historyserver'
          startup: true
        , (err, serviced) ->
          return next err if err
          modified = true if serviced
          do_fix()
      do_fix = ->
        ctx.write
          destination: '/etc/init.d/hadoop-mapreduce-historyserver'
          write: [
            match: /^PIDFILE=".*"$/m
            replace: "PIDFILE=\"#{mapred_pid_dir}/$SVC_USER/mapred-mapred-historyserver.pid\""
          ]
        , (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        next null, if modified then ctx.OK else ctx.PASS
      do_install()

    module.exports.push name: 'HDP MapRed JHS # Kerberos', callback: (ctx, next) ->
      {hadoop_conf_dir, mapred} = ctx.config.hdp
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/mapred-site.xml"
        properties: mapred
        merge: true
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

## HDFS Layout

Layout is inspired by [Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)

    module.exports.push name: 'HDP MapRed JHS # HDFS Layout', timeout: -1, callback: (ctx, next) ->
      {hadoop_group, yarn_user, mapred_user} = ctx.config.hdp
      ctx.execute
        cmd: mkcmd.hdfs ctx, """
        if ! hdfs dfs -test -d /mr-history; then
          hdfs dfs -mkdir -p /mr-history
          hdfs dfs -chmod 0751 /mr-history
          hdfs dfs -chown #{mapred_user.name}:#{hadoop_group.name} /mr-history
          modified=1
        fi
        if ! hdfs dfs -test -d /mr-history/tmp; then
          hdfs dfs -mkdir -p /mr-history/tmp
          hdfs dfs -chmod 1777 /mr-history/tmp
          hdfs dfs -chown #{mapred_user.name}:#{hadoop_group.name} /mr-history/tmp
          modified=1
        fi
        if ! hdfs dfs -test -d /mr-history/done; then
          hdfs dfs -mkdir -p /mr-history/done
          hdfs dfs -chmod 1777 /mr-history/done
          hdfs dfs -chown #{mapred_user.name}:#{hadoop_group.name} /mr-history/done
          modified=1
        fi
        if ! hdfs dfs -test -d /app-logs; then
          hdfs dfs -mkdir -p /app-logs
          hdfs dfs -chmod 1777 /app-logs
          hdfs dfs -chown #{yarn_user.name}:#{hadoop_group.name} /app-logs
          modified=1
        fi
        if [ $modified != "1" ]; then exit 2; fi
        """
        code_skipped: 2
      , (err, executed, stdout) ->
        return next err if err
        next null, if executed then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP MapRed JHS # Kerberos', callback: (ctx, next) ->
      {mapred_user, hadoop_group, realm} = ctx.config.hdp
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc 
        principal: "jhs/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/jhs.service.keytab"
        uid: mapred_user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , (err, created) ->
        return next err if err
        next null, if created then ctx.OK else ctx.PASS

    module.exports.push 'ryba/hadoop/mapred_jhs_start'

# HDP MapRed JHS # Check

Check if the JobHistoryServer is started with an HTTP REST command. Once 
started, the server take some time before it can correctly answer HTTP request.
For this reason, the "retry" property is set to the high value of "10".

    module.exports.push name: 'HDP MapRed JHS # Check', retry: 10, callback: (ctx, next) ->
      {test_user, mapred} = ctx.config.hdp
      [host, port] = mapred['mapreduce.jobhistory.webapp.address'].split ':'
      ctx.execute
        cmd: mkcmd.test ctx, """
        if hdfs dfs -test -f /user/#{test_user.name}/#{ctx.config.host}-jhs; then exit 2; fi
        curl -s --negotiate -u : http://#{host}:#{port}/ws/v1/history/info
        if [ $? != "0" ]; then exit 9; fi
        hdfs dfs -touchz /user/#{test_user.name}/#{ctx.config.host}-jhs
        """
        code_skipped: 2
      , (err, checked, stdout) ->
        return next err if err
        return next null, ctx.PASS unless checked
        try
          JSON.parse(stdout).historyInfo.hadoopVersion
          return next null, ctx.OK
        catch err then next err

[keys]: https://github.com/apache/hadoop-common/blob/trunk/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/DFSConfigKeys.java



