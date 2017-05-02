

    module.exports = ->
      m_ctxs = @contexts 'ryba/hbase/master'
      thrift_ctxs = @contexts 'ryba/hbase/thrift'
      rest_ctxs = @contexts 'ryba/hbase/rest'
      ryba = @config.ryba ?= {}
      {java} = @config
      {realm, hbase, ganglia, graphite} = @config.ryba
      hbase = @config.ryba.hbase ?= {}
      throw Error "No Configured Master" unless m_ctxs.length

# Users and Groups

      hbase.user ?= {}
      hbase.user = name: ryba.hbase.user if typeof ryba.hbase.user is 'string'
      hbase.user.name ?= m_ctxs[0].config.ryba.hbase.user.name
      hbase.user.system ?= m_ctxs[0].config.ryba.hbase.user.system
      hbase.user.comment ?= m_ctxs[0].config.ryba.hbase.user.comment
      hbase.user.home ?= m_ctxs[0].config.ryba.hbase.user.home
      hbase.user.groups ?= m_ctxs[0].config.ryba.hbase.user.groups
      hbase.user.limits ?= {}
      hbase.user.limits.nofile ?= m_ctxs[0].config.ryba.hbase.user.limits.nofile
      hbase.user.limits.nproc ?= m_ctxs[0].config.ryba.hbase.user.limits.nproc
      hbase.admin ?= {}
      hbase.admin.name ?= hbase.user.name
      hbase.admin.principal ?=m_ctxs[0].config.ryba.hbase.admin.principal
      hbase.admin.password ?=m_ctxs[0].config.ryba.hbase.admin.password
      # Group
      hbase.group ?= {}
      hbase.group = name: hbase.group if typeof hbase.group is 'string'
      hbase.group.name ?= m_ctxs[0].config.ryba.hbase.group.name
      hbase.group.system ?= m_ctxs[0].config.ryba.hbase.group.system
      hbase.user.gid = hbase.group.name

# Regionserver Layout

      hbase.rs ?= {}
      hbase.rs.conf_dir ?= '/etc/hbase-regionserver/conf'
      hbase.rs.log_dir ?= '/var/log/hbase'
      hbase.rs.pid_dir ?= '/var/run/hbase'
      hbase.rs.site ?= {}
      hbase.rs.site['hbase.regionserver.port'] ?= '60020'
      hbase.rs.site['hbase.regionserver.info.port'] ?= '60030'
      hbase.rs.site['hbase.ssl.enabled'] ?= 'true'
      hbase.rs.site['hbase.regionserver.handler.count'] ?= 60 # HDP default
      hbase.rs.env ?= {}
      hbase.rs.env['JAVA_HOME'] ?= "#{java.java_home}"
      # http://blog.sematext.com/2012/07/16/hbase-memstore-what-you-should-know/
      # Keep hbase.regionserver.hlog.blocksize * hbase.regionserver.maxlogs just
      hbase.rs.heapsize ?= "256m" #i.e. -Xmx256m
      # a bit above hbase.regionserver.global.memstore.lowerLimit * HBASE_HEAPSIZE
      hbase.rs.java_opts ?= "" #rs.java_opts is build at runtime from the rs.opts object
      hbase.rs.opts ?= {} #represent the java options obect
      hbase.rs.opts['java.security.auth.login.config'] ?= "#{hbase.rs.conf_dir}/hbase-regionserver.jaas"

## Configuration for Kerberos

      hbase.rs.site['hbase.security.authentication'] ?= m_ctxs[0].config.ryba.hbase.master.site['hbase.security.authentication']
      hbase.rs.site['hbase.master.kerberos.principal'] = m_ctxs[0].config.ryba.hbase.master.site['hbase.master.kerberos.principal'] #.replace '_HOST', m_ctxs[0].config.host
      hbase.rs.site['hbase.regionserver.kerberos.principal'] ?= m_ctxs[0].config.ryba.hbase.master.site['hbase.regionserver.kerberos.principal']
      hbase.rs.site['hbase.regionserver.keytab.file'] ?= '/etc/security/keytabs/rs.service.keytab'
      hbase.rs.site['hbase.regionserver.global.memstore.upperLimit'] = null # Deprecated from HDP 2.3
      hbase.rs.site['hbase.regionserver.global.memstore.size'] = '0.4' # Default in HDP Companion Files
      hbase.rs.site['hbase.coprocessor.region.classes'] =  m_ctxs[0].config.ryba.hbase.master.site['hbase.coprocessor.region.classes'] ?= [
        'org.apache.hadoop.hbase.security.token.TokenProvider'
        'org.apache.hadoop.hbase.security.access.SecureBulkLoadEndpoint'
        'org.apache.hadoop.hbase.security.access.AccessController'
      ]
      if @has_service('ryba/hbase/master') and m_ctxs[0].config.ryba.hbase.master.site['hbase.master.kerberos.principal'] isnt hbase.rs.site['hbase.regionserver.kerberos.principal']
        throw Error "HBase principals must match in single node"

## Configuration Distributed mode

      for property in [
        'zookeeper.znode.parent'
        'hbase.cluster.distributed'
        'hbase.rootdir'
        'hbase.zookeeper.quorum'
        'hbase.zookeeper.property.clientPort'
        'dfs.domain.socket.path'
      ] then hbase.rs.site[property] ?= m_ctxs[0].config.ryba.hbase.master.site[property]

## Configuration for HA Reads

HA properties must be available to masters and regionservers.

      properties = [
        'hbase.regionserver.storefile.refresh.period'
        'hbase.regionserver.meta.storefile.refresh.period'
        'hbase.region.replica.replication.enabled'
        'hbase.master.hfilecleaner.ttl' 
        'hbase.master.loadbalancer.class'
        'hbase.meta.replica.count'
        'hbase.region.replica.wait.for.primary.flush'
        'hbase.region.replica.storefile.refresh.memstore.multiplier'
      ]
      for property in properties then hbase.rs.site[property] ?= m_ctxs[0].config.ryba.hbase.master.site[property]

## Configuration for security

      hbase.rs.site['hbase.security.authorization'] ?= m_ctxs[0].config.ryba.hbase.master.site['hbase.security.authorization']
      hbase.rs.site['hbase.rpc.engine'] ?= m_ctxs[0].config.ryba.hbase.master.site['hbase.rpc.engine']
      hbase.rs.site['hbase.superuser'] ?= m_ctxs[0].config.ryba.hbase.master.site['hbase.superuser']
      hbase.rs.site['hbase.bulkload.staging.dir'] ?= m_ctxs[0].config.ryba.hbase.master.site['hbase.bulkload.staging.dir']

## Ranger Plugin Configuration

      @config.ryba.hbase_plugin_is_master = false

## Configuration for Log4J

      hbase.rs.log4j ?= {}
      hbase.rs.opts['hbase.security.log.file'] ?= 'SecurityAuth-Regional.audit'
      #HBase bin script use directly environment bariables
      hbase.rs.env['HBASE_ROOT_LOGGER'] ?= 'INFO,RFA'
      hbase.rs.env['HBASE_SECURITY_LOGGER'] ?= 'INFO,RFAS'
      if @config.log4j?.services?
        if @config.log4j?.remote_host? and @config.log4j?.remote_port? and ('ryba/hbase/regionserver' in @config.log4j?.services)
          # adding SOCKET appender
          hbase.rs.socket_client ?= "SOCKET"
          # Root logger
          if hbase.rs.env['HBASE_ROOT_LOGGER'].indexOf(hbase.rs.socket_client) is -1
          then hbase.rs.env['HBASE_ROOT_LOGGER'] += ",#{hbase.rs.socket_client}"
          # Security Logger
          if hbase.rs.env['HBASE_SECURITY_LOGGER'].indexOf(hbase.rs.socket_client) is -1
          then hbase.rs.env['HBASE_SECURITY_LOGGER']+= ",#{hbase.rs.socket_client}"

          hbase.rs.opts['hbase.log.application'] = 'hbase-regionserver'
          hbase.rs.opts['hbase.log.remote_host'] = @config.log4j.remote_host
          hbase.rs.opts['hbase.log.remote_port'] = @config.log4j.remote_port

          hbase.rs.socket_opts ?=
            Application: '${hbase.log.application}'
            RemoteHost: '${hbase.log.remote_host}'
            Port: '${hbase.log.remote_port}'
            ReconnectionDelay: '10000'

          hbase.rs.log4j = merge hbase.rs.log4j, appender
            type: 'org.apache.log4j.net.SocketAppender'
            name: hbase.rs.socket_client
            logj4: hbase.rs.log4j
            properties: hbase.rs.socket_opts

## Dependencies

    appender = require '../../lib/appender'
    {merge} = require 'nikita/lib/misc'
