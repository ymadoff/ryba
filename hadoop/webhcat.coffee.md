---
title: 
layout: module
---

# WebHCat

    lifecycle = require './lib/lifecycle'
    mkcmd = require './lib/mkcmd'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

https://cwiki.apache.org/confluence/display/Hive/WebHCat+InstallWebHCat
ctx.config.hdp.hive_site['hive.security.metastore.authorization.manager'] ?= 'org.apache.hadoop.hive.ql.security.authorization.StorageBasedAuthorizationProvider'
ctx.config.hdp.hive_site['hive.security.metastore.authenticator.manager'] ?= 'org.apache.hadoop.hive.ql.security.HadoopDefaultMetastoreAuthenticator'
ctx.config.hdp.hive_site['hive.metastore.pre.event.listeners'] ?= 'org.apache.hadoop.hive.ql.security.authorization.AuthorizationPreEventListener'

    module.exports.push module.exports.configure = (ctx) ->
      return if ctx.webhcat_configured
      ctx.webhcat_configured = true
      require('./hive_server').configure ctx
      require('./hdfs').configure ctx
      require('./zookeeper').configure ctx
      {realm} = ctx.config.hdp
      hive_host = ctx.host_with_module 'phyla/hadoop/hive_server'
      zookeeper_hosts = ctx.hosts_with_module 'phyla/hadoop/zookeeper_server'
      for server in ctx.config.servers
        continue if (i = zookeeper_hosts.indexOf server.host) is -1
        zookeeper_hosts[i] = "#{zookeeper_hosts[i]}:#{ctx.config.hdp.zookeeper_port}"
      ctx.config.hdp ?= {}
      ctx.config.hdp.webhcat_conf_dir ?= '/etc/hcatalog/conf/webhcat'
      ctx.config.hdp.webhcat_log_dir ?= '/var/log/webhcat'
      ctx.config.hdp.webhcat_pid_dir ?= '/var/run/webhcat'
      ctx.config.hdp.webhcat_user ?= 'hcat'
      ctx.config.hdp.webhcat_group ?= 'hcat'
      ctx.config.hdp.webhcat_site ?= {}
      ctx.config.hdp.webhcat_site['templeton.hive.properties'] ?= "hive.metastore.local=false,hive.metastore.uris=thrift://#{hive_host}:9083,hive.metastore.sasl.enabled=yes,hive.metastore.execute.setugi=true,hive.metastore.warehouse.dir=/apps/hive/warehouse"
      ctx.config.hdp.webhcat_site['templeton.zookeeper.hosts'] ?= zookeeper_hosts.join ','
      ctx.config.hdp.webhcat_site['templeton.kerberos.principal'] ?= "HTTP/#{ctx.config.host}@#{realm}"
      ctx.config.hdp.webhcat_site['templeton.kerberos.keytab'] ?= '/etc/hcatalog/conf/webhcat/spnego.service.keytab'
      ctx.config.hdp.webhcat_site['templeton.kerberos.secret'] ?= 'secret'
      ctx.config.hdp.webhcat_site['webhcat.proxyuser.hue.groups'] ?= '*'
      ctx.config.hdp.webhcat_site['webhcat.proxyuser.hue.hosts'] ?= '*'
      ctx.config.hdp.webhcat_site['templeton.port'] ?= 50111

    module.exports.push name: 'HDP WebHCat # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service [
        name: 'hcatalog'
      ,
        name: 'webhcat-tar-hive'
      ,
        name: 'webhcat-tar-pig'
      ], (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP WebHCat # Directories', callback: (ctx, next) ->
      {webhcat_log_dir, webhcat_pid_dir, webhcat_user, hadoop_group} = ctx.config.hdp
      modified = false
      do_log = ->
        ctx.mkdir
          destination: webhcat_log_dir
          uid: webhcat_user
          gid: hadoop_group
          mode: 0o755
        , (err, created) ->
          return next err if err
          modified = true if created
          do_pid()
      do_pid = ->
        ctx.mkdir
          destination: webhcat_pid_dir
          uid: webhcat_user
          gid: hadoop_group
          mode: 0o755
        , (err, created) ->
          return next err if err
          modified = true if created
          do_end()
      do_end = ->
        next null, if modified then ctx.OK else ctx.PASS
      do_log()

    module.exports.push name: 'HDP WebHCat # Configuration', callback: (ctx, next) ->
      {webhcat_conf_dir, webhcat_user, hadoop_group, webhcat_site} = ctx.config.hdp
      ctx.hconfigure
        destination: "#{webhcat_conf_dir}/webhcat-site.xml"
        default: "#{__dirname}/files/webhcat/webhcat-site.xml"
        local_default: true
        properties: webhcat_site
        uid: webhcat_user
        gid: hadoop_group
        mode: 0o0755
        merge: true
      , (err, configured) ->
        return next err if err
        next err, if configured then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP WebHCat # Env', callback: (ctx, next) ->
      {webhcat_conf_dir, webhcat_user, hadoop_group} = ctx.config.hdp
      ctx.log 'Write webhcat-env.sh'
      ctx.upload
        source: "#{__dirname}/files/webhcat/webhcat-env.sh"
        destination: "#{webhcat_conf_dir}/webhcat-env.sh"
        uid: webhcat_user
        gid: hadoop_group
        mode: 0o0755
      , (err, uploaded) ->
        next err, if uploaded then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP WebHCat # HDFS', callback: (ctx, next) ->
      {webhcat_user, hadoop_group} = ctx.config.hdp
      ctx.execute
        cmd: mkcmd.hdfs ctx, """
        if hdfs dfs -test -d /user/#{webhcat_user}; then exit 1; fi
        hdfs dfs -mkdir /user/#{webhcat_user}
        hdfs dfs -chown #{webhcat_user}:#{hadoop_group} /user/#{webhcat_user}
        hdfs dfs -mkdir /apps/webhcat
        hdfs dfs -copyFromLocal /usr/share/HDP-webhcat/pig.tar.gz /apps/webhcat/
        hdfs dfs -copyFromLocal /usr/share/HDP-webhcat/hive.tar.gz /apps/webhcat/
        hdfs dfs -copyFromLocal /usr/lib/hadoop-mapreduce/hadoop-streaming*.jar /apps/webhcat/
        hdfs dfs -chown -R #{webhcat_user}:#{hadoop_group} /apps/webhcat
        hdfs dfs -chmod -R 755 /apps/webhcat
        """
        code_skipped: 1
      , (err, executed, stdout) ->
        return next err if err
        next err, if executed then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP WebHCat # SPNEGO', callback: (ctx, next) ->
      {webhcat_site, webhcat_user, webhcat_group} = ctx.config.hdp
      require('./hdfs').configure ctx
      require('./hdfs').spnego ctx, (err, status) ->
        return next err if err
        ctx.copy
          source: '/etc/security/keytabs/spnego.service.keytab'
          destination: webhcat_site['templeton.kerberos.keytab']
          uid: webhcat_user
          gid: webhcat_group
          mode: 0o660
        , (err, copied) ->
          return next err, if copied then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP WebHCat # Start', callback: (ctx, next) ->
      lifecycle.webhcat_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP WebHCat # Check', callback: (ctx, next) ->
      {webhcat_site} = ctx.config.hdp
      port = webhcat_site['templeton.port']
      ctx.execute
        cmd: mkcmd.test ctx, """
        if hdfs dfs -test -f /user/test/check_webhcat; then exit 2; fi
        curl -s --negotiate -u : http://#{ctx.config.host}:#{port}/templeton/v1/status
        hdfs dfs -touchz /user/test/check_webhcat
        """
        code_skipped: 2
      , (err, executed, stdout) ->
        return next err if err
        return next null, ctx.PASS unless executed
        return next new Error "WebHCat not started" if stdout.trim() isnt '{"status":"ok","version":"v1"}'
        return next null, ctx.OK







