---
title: 
layout: module
---

# Hive Server

    url = require 'url'
    path = require 'path'
    mkcmd = require './lib/mkcmd'
    lifecycle = require './lib/lifecycle'
    mkcmd = require './lib/mkcmd'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    # Install the mysql connector
    module.exports.push 'masson/commons/mysql_client'
    # Deploy the HDP repository
    # Configure "core-site.xml" and "hadoop-env.sh"
    module.exports.push 'phyla/hadoop/core'
    # Install kerberos to create and test new Hive principal
    module.exports.push 'masson/core/krb5_client'
    # Install the Hive and HCatalog service
    module.exports.push 'phyla/hadoop/hive_'
    # Validate DNS lookup
    module.exports.push 'masson/core/dns'

    module.exports.push module.exports.configure = (ctx) ->
      return if ctx.hive_server_configured
      ctx.hive_server_configured = true
      require('masson/commons/mysql_server').configure ctx
      require('./hive_').configure ctx
      {hive_site} = ctx.config.hdp
      # Define Users and Groups
      # ctx.config.hdp.mysql_user ?= 'hive'
      # ctx.config.hdp.mysql_password ?= 'hive123'
      # ctx.config.hdp.webhcat_user ?= 'webhcat'
      ctx.config.hdp.hive_log_dir ?= '/var/log/hive'
      ctx.config.hdp.hive_pid_dir ?= '/var/run/hive'
      hive_site['datanucleus.autoCreateTables'] ?= 'true'
      [_, host, port] = /^.*?\/\/?(.*?)(?::(.*))?\/.*$/.exec hive_site['javax.jdo.option.ConnectionURL']
      ctx.config.hdp.hive_jdo_host = host
      ctx.config.hdp.hive_jdo_port = port
      ctx.config.hdp.hive_libs ?= []
      # Prepare database configuration
      hive_admin = ctx.config.hdp.hive_admin ?= {}
      if hive_site['javax.jdo.option.ConnectionURL']
        jdbc = hive_site['javax.jdo.option.ConnectionURL']
        jdbc = jdbc.substr(5) if jdbc.substr(0, 5) is 'jdbc:'
        u = url.parse jdbc
        hive_admin.engine ?= 'mysql' if u.protocol is 'mysql:'
        hive_admin.host ?= u.hostname
        hive_admin.port ?= u.port or '3306'
        hive_admin.db ?= /(\w+)/.exec(u.pathname)[1]
        hive_admin.username ?= 'root'
        if ctx.hosts[hive_admin.host]
          server_conf = ctx.hosts[hive_admin.host].config.mysql_server
          hive_admin.password ?= server_conf['password']
      else 
        mysql_hosts = ctx.hosts_with_module 'masson/commons/mysql_server'
        throw new Error "Expect at least one server with action \"masson/commons/mysql_server\"" if mysql_hosts.length is 0
        mysql_host = if mysql_hosts.length is 1 then mysql_hosts[0] else
          i = mysql_hosts.indexOf(ctx.config.host)
          if i isnt -1 then mysql_hosts[i] else throw new Error "Failed to find a Mysql Server"
        server_conf = ctx.hosts[mysql_host].mysql_server
        hive_admin.engine ?= 'mysql'
        hive_admin.host ?= "#{mysql_host}"
        hive_admin.port ?= '3306'
        hive_admin.db ?= 'hive'
        hive_admin.username ?= 'root'
        hive_admin.password ?= server_conf['password']
        hive_site['javax.jdo.option.ConnectionURL'] ?= "jdbc:mysql://#{mysql_host}:#{hive_admin.port}/#{hive_admin.db}?createDatabaseIfNotExist=true"
      throw new Error "Hive admin database username is required" unless hive_admin.username
      throw new Error "Hive admin database password is required" unless hive_admin.password
      throw new Error "Hive database username is required" unless hive_site['javax.jdo.option.ConnectionUserName']
      throw new Error "Hive database password is required" unless hive_site['javax.jdo.option.ConnectionPassword']

    module.exports.push name: 'HDP Hive & HCat server # Database', callback: (ctx, next) ->
      {hive_site, hive_admin} = ctx.config.hdp
      {engine, host, port, db, username, password} = hive_admin
      ConnectionUserName = hive_site['javax.jdo.option.ConnectionUserName']
      ConnectionPassword = hive_site['javax.jdo.option.ConnectionPassword']
      modified = false
      engines = 
        mysql: ->
          escape = (text) -> text.replace(/[\\"]/g, "\\$&")
          cmd = "mysql -u#{username} -p#{password} -h#{host} -P#{port} -e "
          ctx.execute
            cmd: """
            if #{cmd} "use #{db}"; then exit 2; fi
            #{cmd} "
            create database if not exists #{db};
            grant all privileges on #{db}.* to '#{ConnectionUserName}'@'localhost' identified by '#{ConnectionPassword}';
            grant all privileges on #{db}.* to '#{ConnectionUserName}'@'%' identified by '#{ConnectionPassword}';
            flush privileges;
            "
            """
            code_skipped: 2
          , (err, created, stdout, stderr) ->
            return next err, if created then ctx.OK else ctx.PASS
      return next new Error 'Hive database engine not supported' unless engines[engine]
      engines[engine]()

    module.exports.push name: 'HDP Hive & HCat server # Configure', callback: (ctx, next) ->
      {hive_site, hive_user, hive_group, hive_conf_dir} = ctx.config.hdp
      ctx.hconfigure
        destination: "#{hive_conf_dir}/hive-site.xml"
        default: "#{__dirname}/files/hive/hive-site.xml"
        local_default: true
        properties: hive_site
        merge: true
      , (err, configured) ->
        return next err if err
        ctx.execute
          cmd: """
          chown -R #{hive_user.name}:#{hive_group.name} #{hive_conf_dir}/
          chmod -R 755 #{hive_conf_dir}
          """
        , (err) ->
          next err, if configured then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Hive & HCat server # Fix', callback: (ctx, next) ->
      {hive_conf_dir} = ctx.config.hdp
      ctx.write
        destination: "#{hive_conf_dir}/hive-env.sh"
        match: /^export HIVE_AUX_JARS_PATH=.*$/mg
        replace: 'export HIVE_AUX_JARS_PATH=${HIVE_AUX_JARS_PATH:-/usr/lib/hive-hcatalog/share/hcatalog/hive-hcatalog-core.jar}'
      , (err, written) ->
        next err, if written then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Hive & HCat server # Libs', callback: (ctx, next) ->
      {hive_libs} = ctx.config.hdp
      return next() unless hive_libs.length
      uploads = for lib in hive_libs
        source: lib
        destination: "/usr/lib/hive/lib/#{path.basename lib}"
      ctx.upload uploads, (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Hive & HCat server # Driver', callback: (ctx, next) ->
      ctx.link
        source: '/usr/share/java/mysql-connector-java.jar'
        destination: '/usr/lib/hive/lib/mysql-connector-java.jar'
      , (err, configured) ->
        return next err, if configured then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Hive & HCat server # Kerberos', callback: (ctx, next) ->
      {hive_user, hive_group, hive_site, realm} = ctx.config.hdp
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      modified = false
      do_metastore = ->
        ctx.krb5_addprinc
          principal: hive_site['hive.metastore.kerberos.principal'].replace '_HOST', ctx.config.host
          randkey: true
          keytab: hive_site['hive.metastore.kerberos.keytab.file']
          uid: hive_user.name
          gid: hive_group.name
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: admin_server
        , (err, created) ->
          return next err if err
          modified = true if created
          do_server2()
      do_server2 = ->
        return do_end() if hive_site['hive.metastore.kerberos.principal'] is hive_site['hive.server2.authentication.kerberos.principal']
        ctx.krb5_addprinc
          principal: hive_site['hive.server2.authentication.kerberos.principal'].replace '_HOST', ctx.config.host
          randkey: true
          keytab: hive_site['hive.server2.authentication.kerberos.keytab']
          uid: hive_user.name
          gid: hive_group.name
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: admin_server
        , (err, created) ->
          return next err if err
          modified = true if created
          do_end()
      do_end = ->
        next null, if modified then ctx.OK else ctx.PASS
      do_metastore()

    module.exports.push name: 'HDP Hive & HCat server # Logs', callback: (ctx, next) ->
      ctx.write [
        source: "#{__dirname}/files/hive/hive-exec-log4j.properties.template"
        local_source: true
        destination: '/etc/hive/conf/hive-exec-log4j.properties'
      ,
        source: "#{__dirname}/files/hive/hive-log4j.properties.template"
        local_source: true
        destination: '/etc/hive/conf/hive-log4j.properties'
      ], (err, written) ->
        return next err, if written then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Hive & HCat server # Layout', timeout: -1, callback: (ctx, next) ->
      # todo: this isnt pretty, ok that we need to execute hdfs command from an hadoop client
      # enabled environment, but there must be a better way
      {active_nn_host, hdfs_user, hive_user, hive_group} = ctx.config.hdp
      hive_user = hive_user.name
      hive_group = hive_group.name
      ctx.connect active_nn_host, (err, ssh) ->
        return next err if err
        # kerberos = true
        modified = false
        do_user = ->
          ctx.execute
            ssh: ssh
            cmd: mkcmd.hdfs ctx, """
            if hdfs dfs -ls /user/#{hive_user} &>/dev/null; then exit 1; fi
            hdfs dfs -mkdir -p /user/#{hive_user}
            hdfs dfs -chown -R #{hive_user}:#{hdfs_user} /user/#{hive_user}
            hdfs dfs -chmod -R 775 /apps/#{hive_user}
            """
            code_skipped: 1
            log: ctx.log
            stdout: ctx.log.stdout
            sterr: ctx.log.sterr
          , (err, executed, stdout) ->
            return next err if err
            modified = true if executed
            do_warehouse()
        do_warehouse = ->
          ctx.execute
            ssh: ssh
            cmd: mkcmd.hdfs ctx, """
            if hdfs dfs -ls /apps/#{hive_user}/warehouse &>/dev/null; then exit 3; fi
            hdfs dfs -mkdir /apps/#{hive_user}/warehouse
            hdfs dfs -chown -R #{hive_user}:#{hdfs_user} /apps/#{hive_user}/warehouse
            hdfs dfs -chmod -R 775 /apps/#{hive_user}/warehouse
            """
            code_skipped: 3
            log: ctx.log
            stdout: ctx.log.stdout
            sterr: ctx.log.sterr
          , (err, executed, stdout) ->
            return next err if err
            modified = true if executed
            do_scratch()
        do_scratch = ->
          ctx.execute
            ssh: ssh
            cmd: mkcmd.hdfs ctx, """
            if hdfs dfs -ls /tmp/scratch &> /dev/null; then exit 1; fi
            hdfs dfs -mkdir /tmp 2>/dev/null;
            hdfs dfs -mkdir /tmp/scratch;
            hdfs dfs -chown #{hive_user}:#{hdfs_user} /tmp/scratch;
            hdfs dfs -chmod -R 777 /tmp/scratch;
            """
            code_skipped: 1
            log: ctx.log
            stdout: ctx.log.stdout
            sterr: ctx.log.sterr
          , (err, executed, stdout) ->
            return next err if err
            modified = true if executed
            do_end()
        do_end = ->
          next null, if modified then ctx.OK else ctx.PASS
        do_warehouse()

https://cwiki.apache.org/confluence/display/Hive/LanguageManual+Authorization#LanguageManualAuthorization-MetastoreServerSecurity

    module.exports.push name: 'HDP Hive & HCat server # Metastore Security', callback: (ctx, next) ->
      {hive_conf_dir} = ctx.config.hdp
      hive_site =
        # authorization manager class name to be used in the metastore for authorization.
        # The user defined authorization class should implement interface
        # org.apache.hadoop.hive.ql.security.authorization.HiveMetastoreAuthorizationProvider.
        'hive.security.metastore.authorization.manager': 'org.apache.hadoop.hive.ql.security.authorization.DefaultHiveMetastoreAuthorizationProvider'
        # authenticator manager class name to be used in the metastore for authentication.
        # The user defined authenticator should implement interface 
        # org.apache.hadoop.hive.ql.security.HiveAuthenticationProvider.
        'hive.security.metastore.authenticator.manager': 'org.apache.hadoop.hive.ql.security.HadoopDefaultMetastoreAuthenticator'
        # pre-event listener classes to be loaded on the metastore side to run code
        # whenever databases, tables, and partitions are created, altered, or dropped.
        # Set to org.apache.hadoop.hive.ql.security.authorization.AuthorizationPreEventListener
        # if metastore-side authorization is desired.
        'hive.metastore.pre.event.listeners': ''
      ctx.hconfigure
        destination: "#{hive_conf_dir}/hive-site.xml"
        properties: hive_site
        merge: true
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

todo: Securing the Hive MetaStore 
http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Security-Guide/cdh4sg_topic_9_1.html

todo: Implement lock for Hive Server2
http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Installation-Guide/cdh4ig_topic_18_5.html

    module.exports.push name: 'HDP Hive & HCat server # Start Metastore', callback: (ctx, next) ->
      lifecycle.hive_metastore_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Hive & HCat server # Start Server2', timeout: -1, callback: (ctx, next) ->
      lifecycle.hive_server2_start ctx, (err, started) ->
        next err, if started then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Hive & HCat server # Check', timeout: -1, callback: (ctx, next) ->
      # http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.3.0/CDH4-Security-Guide/cdh4sg_topic_9_1.html
      # !connect jdbc:hive2://big3.big:10000/default;principal=hive/big3.big@ADALTAS.COM 
      next null, ctx.TODO






