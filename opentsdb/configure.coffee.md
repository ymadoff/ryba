

## Configuration

    module.exports = handler: ->
      rs_ctxs = @contexts 'ryba/hbase/regionserver', require('../hbase/regionserver/configure').handler
      throw Error 'No HBase regionservers configured' unless rs_ctxs.length > 0
      {hbase} = rs_ctxs[0].config.ryba
      opentsdb = @config.ryba.opentsdb ?= {}
      # User
      opentsdb.user = name: opentsdb.user if typeof opentsdb.user is 'string'
      opentsdb.user ?= {}
      opentsdb.user.name ?= 'opentsdb'
      opentsdb.user.system ?= true
      opentsdb.user.comment ?= 'OpenTSDB User'
      opentsdb.user.home = '/usr/share/opentsdb'
      # Groups
      opentsdb.group = name: opentsdb.group if typeof opentsdb.group is 'string'
      opentsdb.group ?= {}
      opentsdb.group.name ?= 'opentsdb'
      opentsdb.group.system ?= true
      opentsdb.user.gid = opentsdb.group.name
      # Package
      opentsdb.version ?= "2.2.0"
      opentsdb.source ?= "https://github.com/OpenTSDB/opentsdb/releases/download/v#{opentsdb.version}/opentsdb-#{opentsdb.version}.noarch.rpm"
      # opentsdb.hbase
      opentsdb.hbase ?= {}
      opentsdb.hbase.bloomfilter ?= 'ROW'
      opentsdb.hbase.compression ?= 'SNAPPY'
      throw Error "Invalid opentsdb.hbase.bloomfilter '#{opentsdb.hbase.bloomfilter}' (NONE|ROW|ROWCOL)" unless opentsdb.hbase.bloomfilter in ['NONE', 'ROW', 'ROWCOL']
      throw Error "Invalid opentsdb.hbase.compression '#{opentsdb.hbase.compression}' (NONE|LZO|GZIP|SNAPPY)" unless opentsdb.hbase.compression in ['NONE', 'LZO', 'GZIP', 'SNAPPY']
      # Config
      opentsdb.config ?= {}
      opentsdb.config['tsd.core.auto_create_metrics'] ?= 'true'
      opentsdb.config['tsd.http.staticroot'] ?= "#{opentsdb.user.home}/static/"
      opentsdb.config['tsd.http.cachedir'] ?= '/tmp/opentsdb'
      opentsdb.config['tsd.core.plugin_path'] ?= "#{opentsdb.user.home}/plugins"
      opentsdb.config['tsd.core.meta.enable_realtime_ts'] ?= 'true'
      opentsdb.config['tsd.http.request.cors_domains'] ?= '*'
      opentsdb.config['tsd.network.port'] ?= 4242
      # zookeeper...
      zoo_ctxs = @contexts 'ryba/zookeeper/server'
      opentsdb.config['tsd.storage.hbase.zk_quorum'] ?= zoo_ctxs.map((ctx) -> "#{ctx.config.host}:#{ctx.config.ryba.zookeeper.port}").join ','
      opentsdb.config['tsd.storage.hbase.zk_basedir'] ?= hbase.rs.site['zookeeper.znode.parent']
      opentsdb.config['tsd.storage.hbase.data_table'] ?= 'tsdb'
      opentsdb.config['tsd.storage.hbase.uid_table'] ?= 'tsdb-uid'
      opentsdb.config['tsd.storage.hbase.tree_table'] ?= 'tsdb-tree'
      opentsdb.config['tsd.storage.hbase.meta_table'] ?= 'tsdb-meta'
      opentsdb.config['tsd.query.allow_simultaneous_duplicates'] ?= 'true'
      opentsdb.config['hbase.security.authentication'] ?= hbase.rs.site['hbase.security.authentication']
      if opentsdb.config['hbase.security.authentication'] is 'kerberos'
        opentsdb.config['hbase.security.auth.enable'] ?= 'true' 
        opentsdb.config['hbase.kerberos.regionserver.principal'] ?= hbase.rs.site['hbase.regionserver.kerberos.principal']
        opentsdb.config['java.security.auth.login.config'] ?= '/etc/opentsdb/opentsdb.jaas'
        opentsdb.config['hbase.sasl.clientconfig'] ?= 'Client'
      # Env
      opentsdb.env ?= {}
      opentsdb.env['java.security.auth.login.config'] ?= opentsdb.config['java.security.auth.login.config']
      # Opts
      opentsdb.java_opts ?= ''
