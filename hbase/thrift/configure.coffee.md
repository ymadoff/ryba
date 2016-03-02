
# HBase Thrit Server Configuration

    module.exports = handler: ->
      require('../../hadoop/core/configure').handler.call @
      ryba = @config.ryba ?= {}
      {realm, core_site, ssl_server, hbase} = @config.ryba
      hbase = @config.ryba.hbase ?= {}
      m_ctxs = @contexts 'ryba/hbase/master', require('../master/configure').handler
      throw Error 'No HBase Master configured' unless m_ctxs.length > 1

# Users and Groups

      hbase.test ?= {}
      hbase.test.default_table ?= m_ctxs[0].config.ryba.hbase.test.default_table
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

# Thrift Server Configuration  

      hbase.thrift ?= {}
      hbase.thrift.conf_dir ?= '/etc/hbase-thrift/conf'
      hbase.thrift.log_dir ?= '/var/log/hbase'
      hbase.thrift.pid_dir ?= '/var/run/hbase'
      hbase.thrift.site ?= {}
      hbase.thrift.site['hbase.thrift.port'] ?= '9090' # Default to "8080"
      hbase.thrift.site['hbase.thrift.info.port'] ?= '9095' # Default to "8085"
      hbase.thrift.site['hbase.thrift.ssl.enabled'] ?= 'true'
      hbase.thrift.site['hbase.thrift.ssl.keystore.store'] ?= ssl_server['ssl.server.keystore.location']
      hbase.thrift.site['hbase.thrift.ssl.keystore.password'] ?= ssl_server['ssl.server.keystore.password']
      hbase.thrift.site['hbase.thrift.ssl.keystore.keypassword'] ?= ssl_server['ssl.server.keystore.keypassword']
      # Type of HBase thrift server
      hbase.thrift.site['hbase.regionserver.thrift.server.type'] ?= 'TThreadPoolServer'
      # The value for the property hbase.thrift.security.qop can be one of the following values:
      # auth-conf - authentication, integrity, and confidentiality checking
      # auth-int - authentication and integrity checking
      # auth - authentication checking only
      hbase.thrift.site['hbase.thrift.security.qop'] ?= "auth"
      hbase.thrift.env ?= {}
      hbase.thrift.env['JAVA_HOME'] ?= m_ctxs[0].config.ryba.hbase.master.env['JAVA_HOME']

## Kerberos

*   [HBase docs enables impersonation][hbase-impersonation-mode]
*   [HBaseThrift configuration for hue][hue-thrift-impersonation]
*   [Cloudera docs for Enabling HBase Thrift Impersonation][hbase-configuration-cloudera]


[hue-thrift-impersonation]:http://gethue.com/hbase-browsing-with-doas-impersonation-and-kerberos/
[hbase-impersonation-mode]: http://hbase.apache.org/book.html#security.gateway.thrift
[hbase-configuration-cloudera]:(http://www.cloudera.com/content/www/en-us/documentation/enterprise/latest/topics/cdh_sg_hbase_authentication.html/)

      hbase.thrift.site['hbase.security.authentication'] ?= m_ctxs[0].config.ryba.hbase.master.site['hbase.security.authentication']
      hbase.thrift.site['hbase.security.authorization'] ?= m_ctxs[0].config.ryba.hbase.master.site['hbase.security.authorization']
      hbase.thrift.site['hbase.rpc.engine'] ?= m_ctxs[0].config.ryba.hbase.master.site['hbase.rpc.engine']
      hbase.thrift.site['hbase.thrift.authentication.type'] = hbase.thrift.site['hbase.security.authentication'] ?= 'kerberos'
      hbase.thrift.site['hbase.master.kerberos.principal'] = m_ctxs[0].config.ryba.hbase.master.site['hbase.master.kerberos.principal']
      hbase.thrift.site['hbase.regionserver.kerberos.principal'] = m_ctxs[0].config.ryba.hbase.master.site['hbase.regionserver.kerberos.principal']
      # hbase.site['hbase.thrift.kerberos.principal'] ?= "hbase/_HOST@#{realm}" # Dont forget `grant 'thrift_server', 'RWCA'`
      # hbase.site['hbase.thrift.keytab.file'] ?= "#{hbase.conf_dir}/thrift.service.keytab"
      # Principal changed to http by default in order to enable impersonation and make it work with hue
      hbase.thrift.site['hbase.thrift.kerberos.principal'] ?= "HTTP/#{@config.host}@#{realm}" # was hbase_thrift/_HOST
      hbase.thrift.site['hbase.thrift.keytab.file'] ?= core_site['hadoop.http.authentication.kerberos.keytab']

## Impersonation

      # Enables impersonation
      # For now thrift server does not support impersonation for framed transport: check cloudera setup warning
      hbase.thrift.site['hbase.regionserver.thrift.http'] ?= 'true'
      hbase.thrift.site['hbase.thrift.support.proxyuser'] ?= 'true'
      hbase.thrift.site['hbase.regionserver.thrift.framed'] ?= if hbase.thrift.site['hbase.regionserver.thrift.http'] then 'buffered' else 'framed'

## Proxy Users

      hbase_ctxs = @contexts modules: ['ryba/hbase/master', 'ryba/hbase/regionserver']
      for hbase_ctx in hbase_ctxs
        match = /^(.+?)[@\/]/.exec hbase.thrift.site['hbase.thrift.kerberos.principal']
        throw Error 'Invalid HBase Thrift principal' unless match
        hbase_ctx.config.ryba.hbase ?= {}
        hbase_ctx.config.ryba.hbase.master ?= {}
        hbase_ctx.config.ryba.hbase.master.site ?= {}
        hbase_ctx.config.ryba.hbase.master.site["hadoop.proxyuser.#{match[1]}.groups"] ?= '*'
        hbase_ctx.config.ryba.hbase.master.site["hadoop.proxyuser.#{match[1]}.hosts"] ?= '*'
        hbase_ctx.config.ryba.hbase.rs ?= {}
        hbase_ctx.config.ryba.hbase.rs.site ?= {}
        hbase_ctx.config.ryba.hbase.rs.site["hadoop.proxyuser.#{match[1]}.groups"] ?= '*'
        hbase_ctx.config.ryba.hbase.rs.site["hadoop.proxyuser.#{match[1]}.hosts"] ?= '*'


## Distributed Mode

      for property in [
        'zookeeper.znode.parent'
        'hbase.cluster.distributed'
        'hbase.rootdir'
        'hbase.zookeeper.quorum'
        'hbase.zookeeper.property.clientPort'
        'dfs.domain.socket.path'
      ] then hbase.thrift.site[property] ?= m_ctxs[0].config.ryba.hbase.master.site[property]
