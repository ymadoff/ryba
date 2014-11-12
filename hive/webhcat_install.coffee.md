---
title: 
layout: module
---

# WebHCat

    each = require 'each'
    lifecycle = require '../lib/lifecycle'
    mkcmd = require '../lib/mkcmd'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs' # Install SPNEGO keytab
    module.exports.push require('./webhcat').configure

## IPTables

| Service | Port  | Proto | Info                |
|---------|-------|-------|---------------------|
| webhcat | 50111 | http  | WebHCat HTTP server |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'WebHCat # IPTables', callback: (ctx, next) ->
      {webhcat_site} = ctx.config.ryba
      port = webhcat_site['templeton.port']
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'tcp', state: 'NEW', comment: "WebHCat HTTP Server" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

    module.exports.push name: 'WebHCat # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service [
        name: 'hive-hcatalog'
      ,
        name: 'hive-webhcat'
      ,
        name: 'webhcat-tar-hive'
      ,
        name: 'webhcat-tar-pig'
      ], next

## Startup

Install and configure the startup script in "/etc/init.d/hive-webhcat-server".

    module.exports.push name: 'WebHCat # Startup', callback: (ctx, next) ->
      {webhcat_pid_dir} = ctx.config.ryba
      modified = false
      do_install = ->
        ctx.service
          name: 'hive-webhcat-server'
          startup: true
        , (err, serviced) ->
          return next err if err
          modified = true if serviced
          do_write()
      do_write = ->
        ctx.write [
          destination: '/etc/init.d/hive-webhcat-server'
          match: /^PIDFILE=".*"$/m
          replace: "PIDFILE=\"#{webhcat_pid_dir}/webhcat.pid\""
        ,
          destination: '/etc/init.d/hive-webhcat-server'
          match: /^.*# Ryba: clean pidfile if pid not running$/m
          replace: """
          if pid=`cat $PIDFILE`; then if ! ps -e -o pid | grep -v grep | grep -w $pid; then rm $PIDFILE; fi; fi; \# Ryba: clean pidfile if pid not running
          """
          append: /^PIDFILE=.*$/m
        ], (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        next null, modified
      do_install()

    module.exports.push name: 'WebHCat # Directories', callback: (ctx, next) ->
      {webhcat_log_dir, webhcat_pid_dir, hive_user, hadoop_group} = ctx.config.ryba
      modified = false
      do_log = ->
        ctx.mkdir
          destination: webhcat_log_dir
          uid: hive_user.name
          gid: hadoop_group.name
          mode: 0o755
        , (err, created) ->
          return next err if err
          modified = true if created
          do_pid()
      do_pid = ->
        ctx.mkdir
          destination: webhcat_pid_dir
          uid: hive_user.name
          gid: hadoop_group.name
          mode: 0o755
        , (err, created) ->
          return next err if err
          modified = true if created
          do_end()
      do_end = ->
        next null, modified
      do_log()

    module.exports.push name: 'WebHCat # Configuration', callback: (ctx, next) ->
      {webhcat_conf_dir, hive_user, hadoop_group, webhcat_site} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{webhcat_conf_dir}/webhcat-site.xml"
        default: "#{__dirname}/../resources/webhcat/webhcat-site.xml"
        local_default: true
        properties: webhcat_site
        uid: hive_user.name
        gid: hadoop_group.name
        mode: 0o0755
        merge: true
      , next

    module.exports.push name: 'WebHCat # Env', callback: (ctx, next) ->
      {webhcat_conf_dir, hive_user, hadoop_group} = ctx.config.ryba
      ctx.log 'Write webhcat-env.sh'
      ctx.upload
        source: "#{__dirname}/../resources/webhcat/webhcat-env.sh"
        destination: "#{webhcat_conf_dir}/webhcat-env.sh"
        uid: hive_user.name
        gid: hadoop_group.name
        mode: 0o0755
      , next

    module.exports.push name: 'WebHCat # HDFS', callback: (ctx, next) ->
      {hive_user, hive_group} = ctx.config.ryba
      modified = false
      ctx.execute [
        cmd: mkcmd.hdfs ctx, """
        if hdfs dfs -test -d /user/#{hive_user.name}; then exit 1; fi
        hdfs dfs -mkdir -p /user/#{hive_user.name}
        hdfs dfs -chown #{hive_user.name}:#{hive_group.name} /user/#{hive_user.name}
        """
        code_skipped: 1
      ,
        cmd: mkcmd.hdfs ctx, """
        if hdfs dfs -test -d /apps/webhcat; then exit 1; fi
        hdfs dfs -mkdir -p /apps/webhcat
        """
        code_skipped: 1
      ], (err, created, stdout) ->
        return next err if err
        modified = true if created
        each([
          '/usr/share/HDP-webhcat/pig.tar.gz'
          '/usr/share/HDP-webhcat/hive.tar.gz'
          '/usr/lib/hadoop-mapreduce/hadoop-streaming*.jar'
        ])
        .on 'item', (item, next) ->
          ctx.execute
            cmd: mkcmd.hdfs ctx, "hdfs dfs -copyFromLocal #{item} /apps/webhcat/"
            code_skipped: 1
          , (err, copied) ->
            return next err if err
            modified = true if copied
            next()
        .on 'both', (err) ->
          return next err if err
          ctx.execute
            cmd: mkcmd.hdfs ctx, """
            hdfs dfs -chown -R #{hive_user.name}:users /apps/webhcat
            hdfs dfs -chmod -R 755 /apps/webhcat
            """
          , (err, executed, stdout) ->
            next err, modified

    module.exports.push name: 'WebHCat # Fix HDFS tmp', callback: (ctx, next) ->
      # Avoid HTTP response
      # Permission denied: user=ryba, access=EXECUTE, inode=\"/tmp/hadoop-hcat\":HTTP:hadoop:drwxr-x---
      {hive_user, hadoop_group} = ctx.config.ryba
      modified = false
      ctx.execute [
        cmd: mkcmd.hdfs ctx, """
        if hdfs dfs -test -d /tmp/hadoop-hcat; then exit 2; fi
        hdfs dfs -mkdir -p /tmp/hadoop-hcat
        hdfs dfs -chown HTTP:#{hadoop_group.name} /tmp/hadoop-hcat
        hdfs dfs -chmod -R 1777 /tmp/hadoop-hcat
        """
        code_skipped: 2
      ], next

    module.exports.push name: 'WebHCat # SPNEGO', callback: (ctx, next) ->
      {webhcat_site, hive_user, hadoop_group} = ctx.config.ryba
      ctx.copy
        source: '/etc/security/keytabs/spnego.service.keytab'
        destination: webhcat_site['templeton.kerberos.keytab']
        uid: hive_user.name
        gid: hadoop_group.name
        mode: 0o0660
      , next

    module.exports.push 'ryba/hive/webhcat_start'

    module.exports.push 'ryba/hive/webhcat_check'


# TODO: Check Hive

hdfs dfs -mkdir -p front1-webhcat/mytable
echo -e 'a,1\nb,2\nc,3' | hdfs dfs -put - front1-webhcat/mytable/data
hive
  create database testhcat location '/user/ryba/front1-webhcat';
  create table testhcat.mytable(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
curl --negotiate -u : -d execute="use+testhcat;select+*+from+mytable;" -d statusdir="testhcat1" http://front1.hadoop:50111/templeton/v1/hive
hdfs dfs -cat testhcat1/stderr
hdfs dfs -cat testhcat1/stdout






