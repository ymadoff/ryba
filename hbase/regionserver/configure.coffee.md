

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
      hbase.rs.opts ?= {}
      hbase.rs.opts['java.security.auth.login.config'] ?= "#{hbase.rs.conf_dir}/hbase-regionserver.jaas"
      # http://blog.sematext.com/2012/07/16/hbase-memstore-what-you-should-know/
      # Keep hbase.regionserver.hlog.blocksize * hbase.regionserver.maxlogs just
      # a bit above hbase.regionserver.global.memstore.lowerLimit * HBASE_HEAPSIZE
      hbase.rs_opts ?= "-Xmn128m -Xms4096m -Xmx4096m"

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

## Configuration for HA

HA properties must be available to masters and regionservers.

      if m_ctxs.length > 1
        properties = [
          'hbase.regionserver.storefile.refresh.all'
          'hbase.regionserver.storefile.refresh.period'
          'hbase.region.replica.replication.enabled'
          'hbase.regionserver.storefile.refresh.all'
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

## Proxy Users

      thrift_ctxs = @contexts 'ryba/hbase/thrift', require('../thrift/configure').handler
      if thrift_ctxs.length
        principal = thrift_ctxs[0].config.ryba.hbase.thrift.site['hbase.thrift.kerberos.principal']
        throw Error 'Invalid HBase Thrift principal' unless match = /^(.+?)[@\/]/.exec principal
        hbase.rs.site["hadoop.proxyuser.#{match[1]}.groups"] ?= '*'
        hbase.rs.site["hadoop.proxyuser.#{match[1]}.hosts"] ?= '*'
      rest_ctxs = @contexts 'ryba/hbase/rest', require('../rest/configure').handler
      if rest_ctxs.length
        principal = rest_ctxs[0].config.ryba.hbase.rest.site['hbase.rest.kerberos.principal']
        throw Error 'Invalid HBase Rest principal' unless match = /^(.+?)[@\/]/.exec principal
        hbase.rs.site["hadoop.proxyuser.#{match[1]}.groups"] ?= '*'
        hbase.rs.site["hadoop.proxyuser.#{match[1]}.hosts"] ?= '*'

## Configuration for Log4J

      hbase.rs.opts['hbase.security.log.file'] ?= 'SecurityAuth-regionserver.audit'
      hbase.rs.env['HBASE_ROOT_LOGGER'] ?= 'INFO,RFA'
      hbase.rs.env['HBASE_SECURITY_LOGGER'] ?= 'INFO,RFAS'
      if @config.log4j?.remote_host? && @config.log4j?.remote_port?
        hbase.rs.env['HBASE_ROOT_LOGGER'] ?= 'INFO,RFA,SOCKET'
        hbase.rs.env['HBASE_SECURITY_LOGGER'] ?= 'INFO,RFAS,SOCKET'
        hbase.rs.opts['hbase.log.application'] = 'hbase-regionserver'
        hbase.rs.opts['hbase.log.remote_host'] = @config.log4j.remote_host
        hbase.rs.opts['hbase.log.remote_port'] = @config.log4j.remote_port
