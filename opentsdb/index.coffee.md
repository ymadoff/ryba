
# OpenTSDB

[OpenTSDB][website] is a distributed, scalable Time Series Database (TSDB) written on
top of HBase.  OpenTSDB was written to address a common need: store, index
and serve metrics collected from computer systems (network gear, operating
systems, applications) at a large scale, and make this data easily accessible
and graphable.
OpenTSDB does not seem to work without the hbase rights

    module.exports = []

## Configuration

    module.exports.configure = (ctx) ->
      {hbase} = (ctx.contexts 'ryba/hbase/regionserver', require('../hbase/regionserver').configure)[0].config.ryba
      opentsdb = ctx.config.ryba.opentsdb ?= {}
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
      opentsdb.config['tsd.core.plugin_path'] ?= "#{opentsdb.user.home}/plugins"
      opentsdb.config['tsd.network.port'] ?= 4242
      opentsdb.config['tsd.storage.hbase.zk_basedir'] ?= hbase.site['zookeeper.znode.parent']
      opentsdb.config['hbase.security.authentication'] ?= hbase.site['hbase.security.authentication']
      if opentsdb.config['hbase.security.authentication'] is 'kerberos'
        opentsdb.config['hbase.security.auth.enable'] ?= 'true' 
        opentsdb.config['hbase.kerberos.regionserver.principal'] ?= hbase.site['hbase.regionserver.kerberos.principal']
        opentsdb.config['java.security.auth.login.config'] ?= '/etc/opentsdb/opentsdb.jaas'
        opentsdb.config['hbase.sasl.clientconfig'] ?= 'Client'
      opentsdb.config['tsd.storage.hbase.data_table'] ?= 'tsdb'
      opentsdb.config['tsd.storage.hbase.uid_table'] ?= 'tsdb-uid'
      opentsdb.config['tsd.storage.hbase.tree_table'] ?= 'tsdb-tree'
      opentsdb.config['tsd.storage.hbase.meta_table'] ?= 'tsdb-meta'
      # zookeeper...
      zoo_ctxs = ctx.contexts 'ryba/zookeeper/server'
      opentsdb.config['tsd.storage.hbase.zk_quorum'] ?= (for zoo_ctx in zoo_ctxs then "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.port}").join ','
      # Env
      opentsdb.env ?= {}
      opentsdb.env['java.security.auth.login.config'] ?= '/etc/opentsdb/opentsdb.jaas'
      # Opts
      opentsdb.java_opts ?= ''

## Commands

    module.exports.push commands: 'check', modules: 'ryba/opentsdb/check'

    module.exports.push commands: 'install', modules: [
      'ryba/opentsdb/install'
      'ryba/opentsdb/start'
      'ryba/opentsdb/check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/opentsdb/start'

    module.exports.push commands: 'status', modules: 'ryba/opentsdb/status'

    module.exports.push commands: 'stop', modules: 'ryba/opentsdb/stop'


## Resources

*   [OpentTSDB: Configuration](http://opentsdb.net/docs/build/html/user_guide/configuration.html)

[website]: http://opentsdb.net/

