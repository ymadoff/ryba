
## OpenTSDB Configuration

*   `opentsdb.user` (object|string)   
    The Unix OpenTSDB login name or a user object (see Mecano User documentation).   
*   `opentsdb.group` (object|string)   
    The Unix OpenTSDB group name or a group object (see Mecano Group documentation).   

Example

```json
    "opentsdb": {
      "user": {
        "name": "opentsdb", "system": true, "gid": "opentsdb",
        "comment": "OpenTSDB User", "home": "/usr/share/opentsdb"
      },
      "group": {
        "name": "Opentsdb", "system": true
      }
    }
```

    module.exports = ->
      rs_ctxs = @contexts 'ryba/hbase/regionserver'
      radmin_ctxs = @contexts 'ryba/ranger/admin'
      throw Error 'No HBase regionservers configured' unless rs_ctxs.length > 0
      {hbase} = rs_ctxs[0].config.ryba
      @config.ryba ?= {}
      opentsdb = @config.ryba.opentsdb ?= {}
      # User
      opentsdb.user = name: opentsdb.user if typeof opentsdb.user is 'string'
      opentsdb.user ?= {}
      opentsdb.user.name ?= 'opentsdb'
      opentsdb.user.system ?= true
      opentsdb.user.comment ?= 'OpenTSDB User'
      opentsdb.user.home = '/usr/share/opentsdb'
      opentsdb.user.limits ?= {}
      opentsdb.user.limits.nofile ?= 65535
      opentsdb.user.limits.nproc ?= true
      # Groups
      opentsdb.group = name: opentsdb.group if typeof opentsdb.group is 'string'
      opentsdb.group ?= {}
      opentsdb.group.name ?= 'opentsdb'
      opentsdb.group.system ?= true
      opentsdb.user.gid = opentsdb.group.name
      # Package
      opentsdb.version ?= "2.2.1"
      opentsdb.source ?= "https://github.com/OpenTSDB/opentsdb/releases/download/v#{opentsdb.version}/opentsdb-#{opentsdb.version}.rpm"
      # opentsdb.hbase
      opentsdb.hbase ?= {}
      opentsdb.hbase.default_namespace ?= "opentsdb"
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
      ns = (table) -> if opentsdb.hbase.default_namespace? then "#{opentsdb.hbase.default_namespace}:#{table}" else table
      opentsdb.config['tsd.storage.hbase.data_table'] ?= ns 'tsdb'
      opentsdb.config['tsd.storage.hbase.uid_table'] ?= ns 'tsdb-uid'
      opentsdb.config['tsd.storage.hbase.tree_table'] ?= ns 'tsdb-tree'
      opentsdb.config['tsd.storage.hbase.meta_table'] ?= ns 'tsdb-meta'
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

## Ranger Configuration
Create the opentsdb user if ranger hbase plugin is enabled.

      if radmin_ctxs.length > 0
        [ranger_admin_ctx] = radmin_ctxs
        ranger = ranger_admin_ctx.config.ryba.ranger
        if ranger.plugins.hbase_enabled
          # Ranger HBase Webui xuser
          ranger.users['opentsdb'] ?=
            "name": 'opentsdb'
            "firstName": ''
            "lastName": 'hadoop'
            "emailAddress": 'opentsdb@hadoop.ryba'
            'userSource': 0
            'userRoleList': ['ROLE_USER']
            'groups': []
            'status': 1
