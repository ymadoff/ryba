

## Configuration

See [REST Gateway Impersonation Configuration][impersonation].

[impersonation]: http://hbase.apache.org/book.html#security.rest.gateway

    module.exports = handler: ->
      require('../common/configure').handler.call @
      {realm, core_site, ssl_server, hbase} = @config.ryba
      hbase.rest ?= {}
      hbase.rest.conf_dir ?= '/etc/hbase-rest/conf'
      hbase.rest.log_dir ?= '/var/log/hbase'
      hbase.rest.pid_dir ?= '/var/run/hbase'
      hbase.rest.site ?= {}
      hbase.rest.site['hbase.rest.port'] ?= '60080' # Default to "8080"
      hbase.rest.site['hbase.rest.info.port'] ?= '60085' # Default to "8085"
      hbase.rest.site['hbase.rest.ssl.enabled'] ?= 'true'
      hbase.rest.site['hbase.rest.ssl.keystore.store'] ?= ssl_server['ssl.server.keystore.location']
      hbase.rest.site['hbase.rest.ssl.keystore.password'] ?= ssl_server['ssl.server.keystore.password']
      hbase.rest.site['hbase.rest.ssl.keystore.keypassword'] ?= ssl_server['ssl.server.keystore.keypassword']
      hbase.rest.site['hbase.rest.kerberos.principal'] ?= "hbase_rest/_HOST@#{realm}" # Dont forget `grant 'rest_server', 'RWCA'`
      hbase.rest.site['hbase.rest.keytab.file'] ?= '/etc/security/keytabs/hbase_rest.service.keytab'
      hbase.rest.site['hbase.rest.authentication.type'] ?= 'kerberos'
      hbase.rest.site['hbase.rest.support.proxyuser'] ?= 'true'
      hbase.rest.site['hbase.rest.authentication.kerberos.principal'] ?= "HTTP/_HOST@#{realm}"
      # hbase.site['hbase.rest.authentication.kerberos.keytab'] ?= "#{hbase.conf_dir}/hbase.service.keytab"
      hbase.rest.site['hbase.rest.authentication.kerberos.keytab'] ?= core_site['hadoop.http.authentication.kerberos.keytab']
      m_ctxs = @contexts 'ryba/hbase/master', require('../master/configure').handler
      hbase.rest.site['hbase.security.authentication'] ?= m_ctxs[0].config.ryba.hbase.master.site['hbase.security.authentication']
      hbase.rest.site['hbase.security.authorization'] ?= m_ctxs[0].config.ryba.hbase.master.site['hbase.security.authorization']
      hbase.rest.site['hbase.master.kerberos.principal'] ?= m_ctxs[0].config.ryba.hbase.master.site['hbase.master.kerberos.principal']
      hbase.rest.site['hbase.regionserver.kerberos.principal'] ?= m_ctxs[0].config.ryba.hbase.master.site['hbase.regionserver.kerberos.principal']
      hbase.rest.site['hbase.rpc.engine'] ?= m_ctxs[0].config.ryba.hbase.master.site['hbase.rpc.engine']
      hbase.rest.env ?= {}
      hbase.rest.env['JAVA_HOME'] ?= hbase.env['JAVA_HOME']

## Proxy Users

      hbase_ctxs = @contexts modules: ['ryba/hbase/master', 'ryba/hbase/regionserver']
      for hbase_ctx in hbase_ctxs
        match = /^(.+?)[@\/]/.exec hbase.rest.site['hbase.rest.kerberos.principal']
        throw Error 'Invalid HBase Rest principal' unless match
        hbase_ctx.config.ryba.hbase ?= {}
        hbase_ctx.config.ryba.hbase.master ?= {}
        hbase_ctx.config.ryba.hbase.master.site ?= {}
        hbase_ctx.config.ryba.hbase.master?.site["hadoop.proxyuser.#{match[1]}.groups"] ?= '*'
        hbase_ctx.config.ryba.hbase.master?.site["hadoop.proxyuser.#{match[1]}.hosts"] ?= '*'
        hbase_ctx.config.ryba.hbase.rs ?= {}
        hbase_ctx.config.ryba.hbase.rs.site ?= {}
        hbase_ctx.config.ryba.hbase.rs.site["hadoop.proxyuser.#{match[1]}.groups"] ?= '*'
        hbase_ctx.config.ryba.hbase.rs.site["hadoop.proxyuser.#{match[1]}.hosts"] ?= '*'

## Distributed mode

      properties = [
        'zookeeper.znode.parent'
        'hbase.cluster.distributed'
        'hbase.rootdir'
        'hbase.zookeeper.quorum'
        'hbase.zookeeper.property.clientPort'
        'dfs.domain.socket.path'
      ]
      for property in properties then hbase.rest.site[property] ?=  m_ctxs[0].config.ryba.hbase.master.site[property]
