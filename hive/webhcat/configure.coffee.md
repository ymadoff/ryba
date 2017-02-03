
# Configure webhcat server

    module.exports = ->
      [hcat_ctx] = @contexts 'ryba/hive/hcatalog'
      {ryba} = @config
      throw Error "No Hive HCatalog Server Found" unless hcat_ctx
      webhcat = @config.ryba.webhcat ?= {}
      webhcat.conf_dir ?= '/etc/hive-webhcat/conf'
      webhcat.log_dir ?= '/var/log/webhcat'
      webhcat.pid_dir ?= '/var/run/webhcat'
      # WebHCat configuration
      webhcat.site ?= {}
      webhcat.site['templeton.storage.class'] ?= 'org.apache.hive.hcatalog.templeton.tool.ZooKeeperStorage' # Fix default value distributed in companion files
      webhcat.site['templeton.jar'] ?= '/usr/lib/hive-hcatalog/share/webhcat/svr/lib/hive-webhcat-0.13.0.2.1.2.0-402.jar' # Fix default value distributed in companion files
      webhcat.site['templeton.hive.properties'] ?= [
        'hive.metastore.local=false'
        "hive.metastore.uris=#{hcat_ctx.config.ryba.hive.hcatalog.site['hive.metastore.uris'] }"
        'hive.metastore.sasl.enabled=yes'
        'hive.metastore.execute.setugi=true'
        'hive.metastore.warehouse.dir=/apps/hive/warehouse'
        "hive.metastore.kerberos.principal=HTTP/_HOST@#{hcat_ctx.config.ryba.hive.hcatalog.site['hive.metastore.kerberos.principal']}"
      ].join ','
      webhcat.site['templeton.zookeeper.hosts'] ?= hcat_ctx.config.ryba.hive.hcatalog.site['templeton.zookeeper.hosts']
      webhcat.site['templeton.kerberos.principal'] ?= "HTTP/#{@config.host}@#{ryba.realm}" # "HTTP/#{ctx.config.host}@#{ryba.realm}"
      webhcat.site['templeton.kerberos.keytab'] ?= ryba.core_site['hadoop.http.authentication.kerberos.keytab']
      webhcat.site['templeton.kerberos.secret'] ?= 'secret'
      webhcat.site['webhcat.proxyuser.hue.groups'] ?= '*'
      webhcat.site['webhcat.proxyuser.hue.hosts'] ?= '*'
      webhcat.site['webhcat.proxyuser.knox.groups'] ?= '*'
      webhcat.site['webhcat.proxyuser.knox.hosts'] ?= '*'
      webhcat.site['templeton.port'] ?= 50111
      webhcat.site['templeton.controller.map.mem'] = 1600 # Total virtual memory available to map tasks.

## Java Options

      webhcat.java_opts ?= ''
      webhcat.opts ?= {}

## Logj4 Properties

      webhcat.opts['webhcat.root.logger'] = 'INFO, RFA, socket'
      webhcat.log4j ?= {}
      webhcat.log4j[k] ?= v for k, v of @config.log4j
      webhcat.opts['webhcat.root.logger'] = 'INFO, RFA'
      if @config.log4j?.remote_host? and @config.log4j?.remote_port? and ('ryba/hive/webhcat' in @config.log4j?.services)
        # adding SOCKET appender
        ryba.webhcat.socket_client ?= "SOCKET"
        # Root logger
        if webhcat.opts['webhcat.root.logger'].indexOf(ryba.webhcat.socket_client) is -1
        then webhcat.opts['webhcat.root.logger'] += ",#{ryba.webhcat.socket_client}"

        webhcat.opts['webhcat.log.application'] ?= 'hive-webhcat'
        webhcat.opts['webhcat.log.remote_host'] ?= @config.log4j.remote_host
        webhcat.opts['webhcat.log.remote_port'] ?= @config.log4j.remote_port

        ryba.webhcat.socket_opts ?=
          Application: '${webhcat.log.application}'
          RemoteHost: '${webhcat.log.remote_host}'
          Port: '${webhcat.log.remote_port}'
          ReconnectionDelay: '10000'

        appender
          type: 'org.apache.log4j.net.SocketAppender'
          name: ryba.webhcat.socket_client
          logj4: ryba.webhcat.log4j
          properties: ryba.webhcat.socket_opts

## Dependencies

    appender = require '../../lib/appender'
    {merge} = require 'mecano/lib/misc'
