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
    # Install SPNEGO keytab
    module.exports.push 'ryba/hadoop/hdfs'

# Configure

*   `webhcat_user` (object|string)   
    The Unix WebHCat login name or a user object (see Mecano User documentation).   
*   `webhcat_group` (object|string)   
    The Unix WebHCat group name or a group object (see Mecano Group documentation).   

Example:

```json
{
  "hdp": {
    "webhcat_user": {
      "name": "webhcat", "system": true, "gid": "hcat",
      "comment": "WebHCat User", "home": "/home/hcat"
    }
    "webhcat_group": {
      "name": "webhcat", "system": true
    }
  }
}
```

    module.exports.push module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('./server').configure ctx
      require('../hadoop/hdfs').configure ctx
      require('../zookeeper/server').configure ctx
      {realm} = ctx.config.hdp
      hive_host = ctx.host_with_module 'ryba/hive/server'
      zookeeper_hosts = ctx.hosts_with_module 'ryba/zookeeper/server'
      for server in ctx.config.servers
        continue if (i = zookeeper_hosts.indexOf server.host) is -1
        zookeeper_hosts[i] = "#{zookeeper_hosts[i]}:#{ctx.config.hdp.zookeeper_port}"
      ctx.config.hdp ?= {}
      # ctx.config.hdp.webhcat_conf_dir ?= '/etc/hcatalog/conf/webhcat'
      ctx.config.hdp.webhcat_conf_dir ?= '/etc/hive-webhcat/conf'
      ctx.config.hdp.webhcat_log_dir ?= '/var/log/webhcat'
      ctx.config.hdp.webhcat_pid_dir ?= '/var/run/webhcat'
      # User
      ctx.config.hdp.webhcat_user = name: ctx.config.hdp.webhcat_user if typeof ctx.config.hdp.webhcat_user is 'string'
      ctx.config.hdp.webhcat_user ?= {}
      ctx.config.hdp.webhcat_user.name ?= 'hive'
      ctx.config.hdp.webhcat_user.system ?= true
      ctx.config.hdp.webhcat_user.gid ?= 'hive'
      ctx.config.hdp.webhcat_user.comment ?= 'Hive User'
      ctx.config.hdp.webhcat_user.home ?= '/var/lib/hive'
      # Group
      ctx.config.hdp.webhcat_group = name: ctx.config.hdp.webhcat_group if typeof ctx.config.hdp.webhcat_group is 'string'
      ctx.config.hdp.webhcat_group ?= {}
      ctx.config.hdp.webhcat_group.name ?= 'hive'
      ctx.config.hdp.webhcat_group.system ?= true
      # WebHCat configuration
      ctx.config.hdp.webhcat_site ?= {}
      ctx.config.hdp.webhcat_site['templeton.storage.class'] ?= 'org.apache.hive.hcatalog.templeton.tool.ZooKeeperStorage' # Fix default value distributed in companion files
      ctx.config.hdp.webhcat_site['templeton.jar'] ?= '/usr/lib/hive-hcatalog/share/webhcat/svr/lib/hive-webhcat-0.13.0.2.1.2.0-402.jar' # Fix default value distributed in companion files
      ctx.config.hdp.webhcat_site['templeton.hive.properties'] ?= "hive.metastore.local=false,hive.metastore.uris=thrift://#{hive_host}:9083,hive.metastore.sasl.enabled=yes,hive.metastore.execute.setugi=true,hive.metastore.warehouse.dir=/apps/hive/warehouse"
      ctx.config.hdp.webhcat_site['templeton.zookeeper.hosts'] ?= zookeeper_hosts.join ','
      ctx.config.hdp.webhcat_site['templeton.kerberos.principal'] ?= "HTTP/#{ctx.config.host}@#{realm}"
      ctx.config.hdp.webhcat_site['templeton.kerberos.keytab'] ?= "#{ctx.config.hdp.webhcat_conf_dir}/spnego.service.keytab"
      ctx.config.hdp.webhcat_site['templeton.kerberos.secret'] ?= 'secret'
      ctx.config.hdp.webhcat_site['webhcat.proxyuser.hue.groups'] ?= '*'
      ctx.config.hdp.webhcat_site['webhcat.proxyuser.hue.hosts'] ?= '*'
      ctx.config.hdp.webhcat_site['templeton.port'] ?= 50111
      ctx.config.hdp.webhcat_site['templeton.controller.map.mem'] = 1600 # Total virtual memory available to map tasks.

## Users & Groups

By default, there is not user for WebHCat. This module create the following
entries:

```bash
cat /etc/passwd | grep hcat
hcat:x:494:494:HCat:/var/lib/hcat:/sbin/nologin
cat /etc/group | grep hcat
hcat:x:494:
```

    module.exports.push name: 'WebHCat # Users & Groups', callback: (ctx, next) ->
      {webhcat_group, webhcat_user} = ctx.config.hdp
      ctx.group webhcat_group, (err, gmodified) ->
        return next err if err
        ctx.user webhcat_user, (err, umodified) ->
          next err, if gmodified or umodified then ctx.OK else ctx.PASS

## IPTables

| Service | Port  | Proto | Info                |
|---------|-------|-------|---------------------|
| webhcat | 50111 | http  | WebHCat HTTP server |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'WebHCat # IPTables', callback: (ctx, next) ->
      {webhcat_site} = ctx.config.hdp
      port = webhcat_site['templeton.port']
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'tcp', state: 'NEW', comment: "WebHCat HTTP Server" }
        ]
        if: ctx.config.iptables.action is 'start'
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

    module.exports.push name: 'WebHCat # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service [
        name: 'hive-hcatalog'
      ,
        name: 'hive-webhcat'
      ,
        name: 'webhcat-tar-hive'
      ,
        name: 'webhcat-tar-pig'
      ], (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

## Startup

Install and configure the startup script in "/etc/init.d/hive-webhcat-server".

    module.exports.push name: 'WebHCat # Startup', callback: (ctx, next) ->
      {webhcat_pid_dir} = ctx.config.hdp
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
        next null, if modified then ctx.OK else ctx.PASS
      do_install()

    module.exports.push name: 'WebHCat # Directories', callback: (ctx, next) ->
      {webhcat_log_dir, webhcat_pid_dir, webhcat_user, hadoop_group} = ctx.config.hdp
      modified = false
      do_log = ->
        ctx.mkdir
          destination: webhcat_log_dir
          uid: webhcat_user.name
          gid: hadoop_group.name
          mode: 0o755
        , (err, created) ->
          return next err if err
          modified = true if created
          do_pid()
      do_pid = ->
        ctx.mkdir
          destination: webhcat_pid_dir
          uid: webhcat_user.name
          gid: hadoop_group.name
          mode: 0o755
        , (err, created) ->
          return next err if err
          modified = true if created
          do_end()
      do_end = ->
        next null, if modified then ctx.OK else ctx.PASS
      do_log()

    module.exports.push name: 'WebHCat # Configuration', callback: (ctx, next) ->
      {webhcat_conf_dir, webhcat_user, hadoop_group, webhcat_site} = ctx.config.hdp
      ctx.hconfigure
        destination: "#{webhcat_conf_dir}/webhcat-site.xml"
        default: "#{__dirname}/../hadoop/files/webhcat/webhcat-site.xml"
        local_default: true
        properties: webhcat_site
        uid: webhcat_user.name
        gid: hadoop_group.name
        mode: 0o0755
        merge: true
      , (err, configured) ->
        return next err if err
        next err, if configured then ctx.OK else ctx.PASS

    module.exports.push name: 'WebHCat # Env', callback: (ctx, next) ->
      {webhcat_conf_dir, webhcat_user, hadoop_group} = ctx.config.hdp
      ctx.log 'Write webhcat-env.sh'
      ctx.upload
        source: "#{__dirname}/../hadoop/files/webhcat/webhcat-env.sh"
        destination: "#{webhcat_conf_dir}/webhcat-env.sh"
        uid: webhcat_user.name
        gid: hadoop_group.name
        mode: 0o0755
      , (err, uploaded) ->
        next err, if uploaded then ctx.OK else ctx.PASS

    module.exports.push name: 'WebHCat # HDFS', callback: (ctx, next) ->
      {webhcat_user, webhcat_group} = ctx.config.hdp
      modified = false
      ctx.execute [
        cmd: mkcmd.hdfs ctx, """
        if hdfs dfs -test -d /user/#{webhcat_user.name}; then exit 1; fi
        hdfs dfs -mkdir -p /user/#{webhcat_user.name}
        hdfs dfs -chown #{webhcat_user.name}:#{webhcat_group.name} /user/#{webhcat_user.name}
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
            hdfs dfs -chown -R #{webhcat_user.name}:users /apps/webhcat
            hdfs dfs -chmod -R 755 /apps/webhcat
            """
          , (err, executed, stdout) ->
            next err, if modified then ctx.OK else ctx.PASS

    module.exports.push name: 'WebHCat # Fix HDFS tmp', callback: (ctx, next) ->
      # Avoid HTTP response
      # Permission denied: user=ryba, access=EXECUTE, inode=\"/tmp/hadoop-hcat\":HTTP:hadoop:drwxr-x---
      {webhcat_user, webhcat_group} = ctx.config.hdp
      modified = false
      ctx.execute [
        cmd: mkcmd.hdfs ctx, """
        if hdfs dfs -test -d /tmp/hadoop-hcat; then exit 2; fi
        hdfs dfs -mkdir -p /tmp/hadoop-hcat
        hdfs dfs -chown HTTP:hadoop /tmp/hadoop-hcat
        hdfs dfs -chmod -R 1777 /tmp/hadoop-hcat
        """
        code_skipped: 2
      ], (err, created, stdout) ->
        return next err, if created then ctx.OK else ctx.PASS

    module.exports.push name: 'WebHCat # SPNEGO', callback: (ctx, next) ->
      {webhcat_site, webhcat_user, webhcat_group} = ctx.config.hdp
      ctx.copy
        source: '/etc/security/keytabs/spnego.service.keytab'
        destination: webhcat_site['templeton.kerberos.keytab']
        uid: webhcat_user.name
        gid: webhcat_group.name
        mode: 0o660
      , (err, copied) ->
        return next err, if copied then ctx.OK else ctx.PASS

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






