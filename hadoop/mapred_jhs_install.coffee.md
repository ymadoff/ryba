---
title: 
layout: module
---

# MapRed JobHistoryServer Install

Install and configure the MapReduce Job History Server (JHS).

Run the command `./bin/ryba install -m ryba/hadoop/mapred_jhs` to install the
Job History Server.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    # module.exports.push 'ryba/hadoop/yarn_client_install'
    module.exports.push require('./mapred_jhs').configure

## IPTables

| Service          | Port  | Proto | Parameter                     |
|------------------|-------|-------|-------------------------------|
| jobhistory | 10020 | http  | mapreduce.jobhistory.address        | x
| jobhistory | 19888 | tcp   | mapreduce.jobhistory.webapp.address | x
| jobhistory | 19889 | tcp   | mapreduce.jobhistory.webapp.https.address | x
| jobhistory | 13562 | tcp   | mapreduce.shuffle.port              | x
| jobhistory | 10033 | tcp   | mapreduce.jobhistory.admin.address  |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'Hadoop MapRed JHS # IPTables', callback: (ctx, next) ->
      {mapred_site} = ctx.config.ryba
      jhs_shuffle_port = mapred_site['mapreduce.shuffle.port']
      jhs_port = mapred_site['mapreduce.jobhistory.address'].split(':')[1]
      jhs_webapp_port = mapred_site['mapreduce.jobhistory.webapp.address'].split(':')[1]
      jhs_webapp_https_port = mapred_site['mapreduce.jobhistory.webapp.https.address'].split(':')[1]
      jhs_admin_port = mapred_site['mapreduce.jobhistory.admin.address'].split(':')[1]
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS Server" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_webapp_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS WebApp" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: jhs_webapp_https_port, protocol: 'tcp', state: 'NEW', comment: "MapRed JHS WebApp" }
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
      {hadoop_conf_dir, mapred_site, yarn_site} = ctx.config.ryba
      ctx.hconfigure [
        destination: "#{hadoop_conf_dir}/yarn-site.xml"
        properties: yarn_site
        merge: true
        backup: true
      ,
        destination: "#{hadoop_conf_dir}/mapred-site.xml"
        properties: mapred_site
        merge: true
        backup: true
      ], next

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

## Module dependencies

    lifecycle = require '../lib/lifecycle'
    mkcmd = require '../lib/mkcmd'

[keys]: https://github.com/apache/hadoop-common/blob/trunk/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/DFSConfigKeys.java



