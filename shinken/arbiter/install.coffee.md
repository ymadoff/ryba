
# Shinken Arbiter Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'ryba/shinken'
    module.exports.push require('./index').configure

## IPTables

| Service          | Port  | Proto | Parameter       |
|------------------|-------|-------|-----------------|
| shinken-arbiter  | 7770  |  tcp  |  arbiter.config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'Shinken Arbiter # IPTables', handler: (ctx, next) ->
      {arbiter} = ctx.config.ryba.shinken
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: arbiter.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Arbiter" }
        ]
        if: ctx.config.iptables.action is 'start'
      .then next

## Packages

    module.exports.push name: 'Shinken Arbiter # Packages', handler: (ctx, next) ->
      {shinken} = ctx.config.ryba
      daemon = 'arbiter'
      ctx
      .service
        name: "shinken-#{daemon}"
      .write
        destination: "/etc/init.d/shinken-#{daemon}"
        write: for k, v of {
            'user': shinken.user.name
            'group': shinken.group.name }
          match: ///^#{k}=.*$///mg
          replace: "#{k}=#{v}"
          append: true
      .write
        destination: "/etc/shinken/daemons/#{daemon}d.ini"
        write: for k, v of {
            'user': shinken.user.name
            'group': shinken.group.name }
          match: ///^#{k}=.*$///mg
          replace: "#{k}=#{v}"
          append: true
      .chown
        destination: path.join shinken.log_dir
        uid: shinken.user.name
        gid: shinken.group.name
      .execute
        cmd: "shinken --init"
        not_if_exists: ".shinken.ini"
      .then next

## Additional Modules

    module.exports.push name: 'Shinken Arbiter # Modules', handler: (ctx, next) ->
      {arbiter} = ctx.config.ryba.shinken
      return next() unless Object.getOwnPropertyNames(arbiter.modules).length > 0
      download = []
      extract = []
      exec = []
      for name, mod of arbiter.modules
        if mod.archive?
          download.push
            destination: "#{mod.archive}.zip"
            not_if_exec: "shinken inventory | grep #{name}"
          extract.push
            source: "#{mod.archive}.zip"
            not_if_exec: "shinken inventory | grep #{name}"
          exec.push
            cmd: "shinken install --local #{mod.archive}"
            not_if_exec: "shinken inventory | grep #{name}"
        else return next Error "Missing parameter: archive for arbiter.modules.#{name}"
      ctx
      .download download
      .extract extract
      .execute exec
      .then next

## Ownership

    # module.exports.push name: 'Shinken Arbiter # Permissions', handler: (ctx, next) ->
    #   {shinken} = ctx.config.ryba
    #   ch = for p in [shinken.log_dir, shinken.plugin_dir, '/var/lib/shinken']
    #     destination: p
    #     uid: shinken.user.name
    #     gid: shinken.group.name
    #     recursive: true
    #   ctx
    #   .chown ch
    #   .then next

## Configuration

    module.exports.push name: 'Shinken Arbiter # Commons Config', handler: (ctx, next) ->
      {shinken} = ctx.config.ryba
      render_ctx = {}
      render_ctx[k] = v for k, v of shinken.config
      render_ctx.hosts = []
      render_ctx.hosts.push server for server, k of ctx.config.servers
      render = for hdp_obj in ['commands', 'contactgroups','contacts','hostgroups', 'hosts','servicegroups', 'templates']
        destination: "/etc/shinken/#{hdp_obj}/hadoop-#{hdp_obj}.cfg"
        source: "#{__dirname}/../../resources/shinken/#{hdp_obj}/hadoop-#{hdp_obj}.cfg.j2"
        local_source: true
        context: render_ctx
      ctx
      .render render
      .write
        destination: '/etc/shinken/shinken.cfg'
        write: for k, v of {
          'date_format': 'iso8601'
          'shinken_user': shinken.user.name
          'shinken_group': shinken.group.name }
            match: ///^#{k}=.*$///mg
            replace: "#{k}=#{v}"
            append: true
        eof: true
      .write
        destination: '/etc/shinken/resource.d/path.cfg'
        match: /^\$PLUGINSDIR\$=.*$/mg
        replace: "$PLUGINSDIR$=#{shinken.plugin_dir}"
      .then next

## Plugins

    module.exports.push name: 'Shinken Arbiter # Plugins', timeout: -1, handler: (ctx, next) ->
      {shinken} = ctx.config.ryba
      glob "#{__dirname}/../../resources/shinken/plugins/*", (err, plugins) ->
        return next err if err
        plugins = for plugin in plugins
          source: plugin
          destination: "#{shinken.plugin_dir}/#{path.basename plugin}"
          uid: shinken.user.name
          gid: shinken.group.name
          mode: 0o0775
        ctx
        .download plugins
        .then next

## Services

    module.exports.push name: 'Shinken Arbiter # Services Config', handler: (ctx, next) ->
      {shinken, force_check, active_nn_host, core_site, hdfs, zookeeper,
        hbase, oozie, webhcat, ganglia, hue} = ctx.config.ryba
      protocol = if hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      # HDFS NameNode
      nn_hosts = ctx.hosts_with_module 'ryba/hadoop/hdfs_nn'
      nn_hosts_map = {} # fqdn to port
      active_nn_port = null
      unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
        u = url.parse core_site['fs.defaultFS']
        nn_hosts_map[u.hostname] = u.port
        active_nn_port = u.port
      else
        for nn_host in nn_hosts
          nn_ctx = ctx.hosts[nn_host]
          require('../../hadoop/hdfs_nn').configure nn_ctx
          protocol = if nn_ctx.config.ryba.hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
          shortname = nn_ctx.config.shortname
          nameservice = nn_ctx.config.ryba.nameservice
          nn_host = ctx.config.ryba.hdfs.site["dfs.namenode.#{protocol}-address.#{nameservice}.#{shortname}"].split(':')
          nn_hosts_map[nn_host[0]] = nn_host[1]
          active_nn_port = nn_host[1] if nn_ctx.config.host is active_nn_host
      # HDFS Secondary NameNode
      [snn_ctx] = ctx.contexts 'ryba/hadoop/hdfs_snn', require('../../hadoop/hdfs_snn').configure
      # YARN ResourceManager
      rm_ctxs = ctx.contexts 'ryba/hadoop/yarn_rm', require('../../hadoop/yarn_rm').configure
      rm_hosts = rm_ctxs.map (rm_ctx) -> rm_ctx.config.host
      # Get RM UI port for both HA and non-HA
      rm_site = rm_ctxs[0].config.ryba.yarn.site
      unless rm_ctxs.length > 1
        rm_webapp_port = if rm_site['yarn.http.policy'] is 'HTTP_ONLY'
        then rm_site['yarn.resourcemanager.webapp.address'].split(':')[1]
        else rm_site['yarn.resourcemanager.webapp.https.address'].split(':')[1]
      else
        shortname = rm_ctxs[0].config.shortname
        rm_webapp_port = if rm_site['yarn.http.policy'] is 'HTTP_ONLY'
        then rm_site["yarn.resourcemanager.webapp.address.#{shortname}"].split(':')[1]
        else rm_site["yarn.resourcemanager.webapp.https.address.#{shortname}"].split(':')[1]
      # YARN NodeManager
      nm_ctxs = ctx.contexts 'ryba/hadoop/yarn_nm', require('../../hadoop/yarn_nm').configure
      if nm_ctxs.length
        nm_webapp_port = if nm_ctxs[0].config.ryba.yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
        then nm_ctxs[0].config.ryba.yarn.site['yarn.nodemanager.webapp.address'].split(':')[1]
        else nm_ctxs[0].config.ryba.yarn.site['yarn.nodemanager.webapp.https.address'].split(':')[1]
      # MapReduce JobHistoryServer
      jhs_ctxs = ctx.contexts 'ryba/hadoop/mapred_jhs', require('../../hadoop/mapred_jhs').configure
      if jhs_ctxs.length
        hs_webapp_port = jhs_ctxs[0].config.ryba.mapred.site['mapreduce.jobhistory.webapp.address'].split(':')[1]
      # HDFS JournalNodes
      jn_ctxs = ctx.contexts 'ryba/hadoop/hdfs_jn', require('../../hadoop/hdfs_jn').configure
      if jn_ctxs.length
        journalnode_port = jn_ctxs[0].config.ryba.hdfs.site["dfs.journalnode.#{protocol}-address"].split(':')[1]
      # HDFS Datanodes
      [dn_ctx] = ctx.contexts 'ryba/hadoop/hdfs_dn', require('../../hadoop/hdfs_dn').configure
      dn_protocol = if dn_ctx.config.ryba.hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      dn_port = dn_ctx.config.ryba.hdfs.site["dfs.datanode.#{protocol}.address"].split(':')[1]
      # HBase
      hm_hosts = ctx.hosts_with_module 'ryba/hbase/master'
      # Hive
      hcat_ctxs = ctx.contexts 'ryba/hive/hcatalog', require('../../hive/hcatalog').configure
      hs2_ctxs = ctx.contexts 'ryba/hive/server2', require('../../hive/server2').configure
      hs2_port = if hs2_ctxs[0].config.ryba.hive.site['hive.server2.transport.mode'] is 'binary'
      then 'hive.server2.thrift.port'
      else 'hive.server2.thrift.http.port'
      hs2_port = hs2_ctxs[0].config.ryba.hive.site[hs2_port]
      ctx.render
        source: "#{__dirname}/../../resources/shinken/services/hadoop-services.cfg.j2"
        local_source: true
        destination: '/etc/shinken/services/hadoop-services.cfg'
        context:
          hostgroups: shinken.config.hostgroups
          all_hosts: [] # Ambari agents
          shinken_lookup_daemon_str: '/usr/sbin/shinken'
          namenode_port: active_nn_port
          dfs_ha_enabled: not ctx.host_with_module 'ryba/hadoop/hdfs_snn'
          all_ping_ports: null # Ambari agent ports
          ganglia_port: ganglia.collector_port
          ganglia_collector_namenode_port: ganglia.nn_port
          ganglia_collector_hbase_port: ganglia.hm_port
          ganglia_collector_rm_port: ganglia.rm_port
          ganglia_collector_hs_port: ganglia.jhs_port
          snamenode_port: snn_ctx?.config.ryba.hdfs.site['dfs.namenode.secondary.http-address'].split(':')[1]
          storm_ui_port: 0 # TODO Storm
          nimbus_port: 0 # TODO Storm
          drpc_port: 0 # TODO Storm
          storm_rest_api_port: 0 # TODO Storm
          supervisor_port: 0 # TODO Storm
          hadoop_ssl_enabled: protocol is 'https'
          shinken_keytab_path: shinken.keytab
          shinken_principal_name: shinken.principal
          kinit_path_local: shinken.kinit
          security_enabled: true
          nn_ha_host_port_map: nn_hosts_map
          namenode_host: nn_hosts
          nn_hosts_string: nn_hosts.join ' '
          dfs_namenode_checkpoint_period: hdfs.site['dfs.namenode.checkpoint.period'] or 21600
          dfs_namenode_checkpoint_txns: hdfs.site['dfs.namenode.checkpoint.txns'] or 1000000
          nn_metrics_property: 'FSNamesystem'
          rm_hosts_in_str: rm_hosts.join ','
          rm_port: rm_webapp_port
          nm_port: nm_webapp_port
          hs_port: hs_webapp_port
          journalnode_port: journalnode_port
          datanode_port: dn_port
          clientPort: zookeeper.port
          hbase_rs_port: hbase.site['hbase.regionserver.info.port']
          hbase_master_port: hbase.site['hbase.master.info.port']
          hbase_master_hosts_in_str: hm_hosts.join ','
          hbase_master_hosts: hm_hosts
          hbase_master_rpc_port: hbase.site['hbase.master.port']
          hive_metastore_port: url.parse(hcat_ctxs[0].config.ryba.hive.site['hive.metastore.uris']).port
          hive_server_port: hs2_port
          oozie_url: oozie.site['oozie.base.url']
          java64_home: ctx.config.java.java_home # Used by check_oozie_status.sh
          templeton_port: webhcat.site['templeton.port']
          falcon_port: 0 # TODO
          ahs_port: 0 # TODO
          hue_port: parseInt hue.ini.desktop['http_port']
      .then next

    module.exports.push name: 'Shinken Arbiter # Shinken Config', handler: (ctx, next) ->
      {shinken} = ctx.config.ryba
      render_ctx = {}
      for s_module in ['arbiter', 'broker', 'poller', 'reactionner', 'receiver', 'scheduler']
        render_ctx["#{s_module}s"] = []
        ctxs = ctx.contexts "ryba/shinken/#{s_module}", require("../#{s_module}").configure
        for _ctx in ctxs
          config = {}
          config[k] = v for k, v of _ctx.config.ryba.shinken[s_module].config
          config.host = _ctx.config.host
          render_ctx["#{s_module}s"].push config
      render = for s_module in ['arbiter', 'broker', 'poller', 'reactionner', 'receiver', 'scheduler']
        destination: "/etc/shinken/#{s_module}s/#{s_module}-master.cfg"
        source: "#{__dirname}/../../resources/shinken/#{s_module}s/#{s_module}-master.cfg.j2"
        local_source: true
        context: render_ctx
      ctx
      .render render
      .then next


### Configure

    module.exports.push name: 'Shinken Arbiter # Modules Config', handler: (ctx, next) ->
      render = []
      for s_module in ['arbiter', 'broker', 'poller', 'reactionner', 'receiver', 'scheduler']
        ctxs = ctx.contexts "ryba/shinken/#{s_module}", require("../#{s_module}").configure
        for name, mod of ctxs[0].config.ryba.shinken[s_module].modules
          render.push
            destination: "/etc/shinken/modules/#{name}.cfg"
            source:  "#{__dirname}/../../resources/shinken/modules/#{name}.cfg.j2"
            local_source: true
            context: mod.config
            if: mod.config?
      ctx
      .render render
      .then next

## Module Dependencies

    path = require 'path'
    url = require 'url'
    glob = require 'glob'
