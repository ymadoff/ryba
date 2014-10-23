---
title: 
layout: module
---

# MapRed JobHistoryServer

    lifecycle = require '../lib/lifecycle'
    mkcmd = require '../lib/mkcmd'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/mapred'

    module.exports.push module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('./mapred').configure ctx
      mapred_site = ctx.config.ryba.mapred_site
      mapred_site['mapreduce.jobhistory.keytab'] ?= "/etc/security/keytabs/jhs.service.keytab"
      # Fix: src in "[DFSConfigKeys.java][keys]" and [HDP port list] mention 13562 while companion files mentions 8081
      mapred_site['mapreduce.shuffle.port'] ?= '13562'
      mapred_site['mapreduce.jobhistory.address'] ?= "#{ctx.config.host}:10020"
      mapred_site['mapreduce.jobhistory.webapp.address'] ?= "#{ctx.config.host}:19888"
      mapred_site['mapreduce.jobhistory.webapp.https.address'] ?= "#{ctx.config.host}:19888"
      mapred_site['mapreduce.jobhistory.admin.address'] ?= "#{ctx.config.host}:10033"
      # See './hadoop-mapreduce-project/hadoop-mapreduce-client/hadoop-mapreduce-client-common/src/main/java/org/apache/hadoop/mapreduce/v2/jobhistory/JHAdminConfig.java#158'
      # yarn_site['mapreduce.jobhistory.webapp.spnego-principal']
      # yarn_site['mapreduce.jobhistory.webapp.spnego-keytab-file']

## IPTables

| Service          | Port  | Proto | Parameter                     |
|------------------|-------|-------|-------------------------------|
| jobhistory | 10020 | http  | mapreduce.jobhistory.address        | x
| jobhistory | 19888 | tcp   | mapreduce.jobhistory.webapp.address | x
| jobhistory | 13562 | tcp   | mapreduce.shuffle.port              | x
| jobhistory | 10033 | tcp   | mapreduce.jobhistory.admin.address  |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'Hadoop MapRed JHS # IPTables', callback: (ctx, next) ->
      {mapred_site} = ctx.config.ryba
      jhs_shuffle_port = mapred_site['mapreduce.shuffle.port']
      jhs_port = mapred_site['mapreduce.jobhistory.address'].split(':')[1]
      jhs_webapp_port = mapred_site['mapreduce.jobhistory.webapp.address'].split(':')[1]
      jhs_admin_port = mapred_site['mapreduce.jobhistory.admin.address'].split(':')[1]
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS Server" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_webapp_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS WebApp" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_shuffle_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS Shuffle" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_admin_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS Admin Server" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Startup

Install and configure the startup script in 
"/etc/init.d/hadoop-mapreduce-historyserver".

    module.exports.push name: 'Hadoop MapRed JHS # Startup', callback: (ctx, next) ->
      {mapred_pid_dir} = ctx.config.ryba
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
          ,
            match: /^(\s+start_daemon)\s+(\$EXEC_PATH.*)$/m
            replace: "$1 -u $SVC_USER $2"
          ]
        , (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        next null, modified
      do_install()

    module.exports.push name: 'Hadoop MapRed JHS # Kerberos', callback: (ctx, next) ->
      {hadoop_conf_dir, mapred_site} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/mapred-site.xml"
        properties: mapred_site
        merge: true
      , next

## HDFS Layout

Layout is inspired by [Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)

    module.exports.push name: 'Hadoop MapRed JHS # HDFS Layout', timeout: -1, callback: (ctx, next) ->
      {hadoop_group, yarn_user, mapred_user} = ctx.config.ryba
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
      , next

    module.exports.push name: 'Hadoop MapRed JHS # Kerberos', callback: (ctx, next) ->
      {mapred_user, hadoop_group, realm} = ctx.config.ryba
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
      , next

    module.exports.push 'ryba/hadoop/mapred_jhs_start'

# HDP MapRed JHS # Check

Check if the JobHistoryServer is started with an HTTP REST command. Once 
started, the server take some time before it can correctly answer HTTP request.
For this reason, the "retry" property is set to the high value of "10".

    module.exports.push name: 'Hadoop MapRed JHS # Check', retry: 10, callback: (ctx, next) ->
      {test_user, yarn_site, mapred_site} = ctx.config.ryba
      protocol = if yarn_site['yarn.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      [host, port] = if protocol is 'http'
      then mapred_site['mapreduce.jobhistory.webapp.address'].split ':'
      else mapred_site['mapreduce.jobhistory.webapp.https.address'].split ':'
      ctx.execute
        cmd: mkcmd.test ctx, """
        if hdfs dfs -test -f /user/#{test_user.name}/#{ctx.config.host}-jhs; then exit 2; fi
        curl -s --insecure --negotiate -u : #{protocol}://#{host}:#{port}/ws/v1/history/info
        if [ $? != "0" ]; then exit 9; fi
        hdfs dfs -touchz /user/#{test_user.name}/#{ctx.config.host}-jhs
        """
        code_skipped: 2
      , (err, checked, stdout) ->
        return next err if err
        return next null, false unless checked
        try
          JSON.parse(stdout).historyInfo.hadoopVersion
          return next null, true
        catch err then next err

[keys]: https://github.com/apache/hadoop-common/blob/trunk/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/DFSConfigKeys.java



