
# Nagios Install

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/commons/httpd'
    module.exports.push 'masson/commons/java'
    module.exports.push 'ryba/oozie/client' # Used by check_oozie_status.sh

    module.exports.push require('./index').configure

    module.exports.push name: 'Nagios # Kerberos', callback: (ctx, next) ->
      {nagios, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc 
        principal: nagios.principal
        randkey: true
        keytab: nagios.keytab
        uid: nagios.user.name
        gid: nagios.user.group
        mode: 0o600
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next

## Users & Groups

By default, the "hbase" package create the following entries:

```bash
cat /etc/passwd | grep hbase
nagios:x:2418:2418:nagios:/var/log/nagios:/bin/sh
cat /etc/group | grep hbase
nagios:x:2418:
nagiocmd:x:2419:apache
```

    module.exports.push name: 'Nagios # Users & Groups', callback: (ctx, next) ->
      {nagios} = ctx.config.ryba
      ctx.group [nagios.group, nagios.groupcmd], (err, gmodified) ->
        return next err if err
        ctx.user nagios.user, (err, umodified) ->
          next err, gmodified or umodified

    module.exports.push name: 'Nagios # Service', callback: (ctx, next) ->
      ctx.service [
        {name: 'net-snmp'}
        {name: 'net-snmp-utils'}
        {name: 'php-pecl-json'}
        {name: 'wget'}
        {name: 'httpd'}
        {name: 'php'}
        {name: 'net-snmp-perl'}
        {name: 'perl-Net-SNMP'}
        {name: 'fping'}
        {name: 'nagios', startup: true}
        {name: 'nagios-plugins'}
        {name: 'nagios-www'}
      ], next

    module.exports.push name: 'Nagios # Layout', callback: (ctx, next) ->
      {user, group, groupcmd} = ctx.config.ryba.nagios
      ctx.mkdir [
        destination: [
          '/var/nagios', '/var/log/nagios',
          '/var/log/nagios/spool/checkresults', '/var/run/nagios'
        ]
        uid: user.name
        gid: group.name
      ,
        destination: '/var/nagios/rw'
        uid: user.name
        gid: groupcmd.name
        mode: 0o2770
      ], next

# Objects

    module.exports.push name: 'Nagios # Objects', callback: (ctx, next) ->
      {user, group, overwrite} = ctx.config.ryba.nagios
      objects = [
        'hadoop-commands', 'hadoop-hosts'
        'nagios'
      ]
      objects = for object in objects
        source = if object is 'nagios'
        then 'nagios.cfg-centos'
        else "#{object}.cfg"
        source: "#{__dirname}/../resources/nagios/objects/#{source}"
        destination: "/etc/nagios/objects/#{object}.cfg"
        uid: user.name
        gid: group.name
        mode: 0o0644
        not_if_exists: !overwrite
      ctx.upload objects, next

# Plugins

    module.exports.push name: 'Nagios # Plugins', timeout: -1, callback: (ctx, next) ->
      {user, group, plugin_dir} = ctx.config.ryba.nagios
      glob "#{__dirname}/../resources/nagios/plugins/*", (err, plugins) ->
        return next err if err
        plugins = for plugin in plugins
          plugin = path.basename plugin
          source: "#{__dirname}/../resources/nagios/plugins/#{plugin}"
          destination: "#{plugin_dir}/#{plugin}"
          uid: user.name
          gid: group.name
          mode: 0o0775
        ctx.upload plugins, next

    module.exports.push name: 'Nagios # Admin Password', callback: (ctx, next) ->
      {user, group, admin} = ctx.config.ryba.nagios
      ctx.execute
        cmd: """
        hash=`cat /etc/nagios/htpasswd.users 2>/dev/null | grep #{admin.name}: | sed 's/.*:\\(.*\\)/\\1/'`
        salt=`echo $hash | sed 's/\\(.\\{2\\}\\).*/\\1/'`
        if [ $salt != "" ]; then
          expect=`openssl passwd -crypt -salt $salt #{admin.password} 2>/dev/null`
          if [ "$hash" == "$expect" ]; then exit 3; fi
        fi
        htpasswd -c -b  /etc/nagios/htpasswd.users #{admin.name} #{admin.password}
        """
        code_skipped: 3
      , next

    module.exports.push name: 'Nagios # Admin Email', callback: (ctx, next) ->
      {user, group, admin_email} = ctx.config.ryba.nagios
      ctx.write
        destination: '/etc/nagios/objects/contacts.cfg'
        match: /^(\s*email\s+)([^\s]+)(\s*;.*)$/mg
        replace: "$1#{admin_email}$3"
      , next

    module.exports.push name: 'Nagios # Configuration', callback: (ctx, next) ->
      {user, group, plugin_dir} = ctx.config.ryba.nagios
      # Register Hadoop configuration files
      cfg_files = [
        'hadoop-commands', 'hadoop-hostgroups', 'hadoop-hosts'
        'hadoop-servicegroups', 'hadoop-services'
      ]
      write = for cfg in cfg_files
        replace: "cfg_file=/etc/nagios/objects/#{cfg}.cfg"
        append: true
        eof: true
      # Update configuration parameters
      cfgs = 
        'command_file': '/var/nagios/rw/nagios.cmd'
        'precached_object_file': '/var/nagios/objects.precache'
        'resource_file': '/etc/nagios/resource.cfg'
        'status_file': '/var/nagios/status.dat'
        'command_file': '/var/nagios/rw/nagios.cmd'
        'temp_file': '/var/nagios/nagios.tmp'
        'date_format': 'iso8601'
      for k, v of cfgs
        write.push 
          match: ///^#{k}=.*$///mg
          replace: "#{k}=#{v}"
          append: true
      ctx.write [
        destination: '/etc/nagios/nagios.cfg'
        write: write
        eof: true
      ,
        destination: '/etc/nagios/resource.cfg'
        match: /^\$USER1\$=.*$/mg
        replace: "$USER1$=#{plugin_dir}"
      ], next

    module.exports.push name: 'Nagios # Hosts', callback: (ctx, next) ->
      {user, group} = ctx.config.ryba.nagios
      content = for host of ctx.config.servers
        """
        define host {
             alias #{host}
             host_name #{host}
             use linux-server
             address #{host}
             check_interval 0.25
             retry_interval 0.25
             max_check_attempts 4
             notifications_enabled 1
             first_notification_delay 0 # Send notification soon after change in the hard state
             notification_interval 0    # Send the notification once
             notification_options       d,u,r
        }
        """
      ctx.write
        destination: '/etc/nagios/objects/hadoop-hosts.cfg'
        content: content.join '\n'
        eof: true
      , next

## Nagios # Host Groups

The following command list all the referenced host groups:

```
cat /etc/nagios/objects/hadoop-services.cfg | grep hostgroup_name
```

    module.exports.push name: 'Nagios # Host Groups', callback: (ctx, next) ->
      {nagios} = ctx.config.ryba
      hostgroup_defs = {}
      for group, hosts of nagios.hostgroups
        hostgroup_defs[group] = if hosts.length then hosts else null
      ctx.render
        source: "#{__dirname}/../resources/nagios/templates/hadoop-hostgroups.cfg.j2"
        local_source: true
        destination: '/etc/nagios/objects/hadoop-hostgroups.cfg'
        context:
          all_hosts: Object.keys ctx.config.servers
          hostgroup_defs: hostgroup_defs
      , next

    module.exports.push name: 'Nagios # Services Groups', callback: (ctx, next) ->
      {nagios} = ctx.config.ryba
      hostgroup_defs = {}
      for group, hosts of nagios.hostgroups
        hostgroup_defs[group] = if hosts.length then hosts else null
      ctx.render
        source: "#{__dirname}/../resources/nagios/templates/hadoop-servicegroups.cfg.j2"
        local_source: true
        destination: '/etc/nagios/objects/hadoop-servicegroups.cfg'
        context:
          hostgroup_defs: hostgroup_defs
      , next

    module.exports.push name: 'Nagios # Services', callback: (ctx, next) ->
      {nagios, force_check, active_nn_host, core_site, hdfs_site, zookeeper_port, 
        yarn, hive_site, hbase_site, oozie_site, webhcat_site, ganglia, hue} = ctx.config.ryba
      protocol = if hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
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
          require('../hadoop/hdfs_nn').configure nn_ctx
          protocol = if nn_ctx.config.ryba.hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
          shortname = nn_ctx.config.shortname
          nameservice = nn_ctx.config.ryba.nameservice
          nn_host = ctx.config.ryba.ha_client_config["dfs.namenode.#{protocol}-address.#{nameservice}.#{shortname}"].split(':')
          nn_hosts_map[nn_host[0]] = nn_host[1]
          active_nn_port = nn_host[1] if nn_ctx.config.host is active_nn_host
      rm_hosts = ctx.hosts_with_module 'ryba/hadoop/yarn_rm'
      rm_webapp_port = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
      then yarn.site['yarn.resourcemanager.webapp.address'].split(':')[1]
      else yarn.site['yarn.resourcemanager.webapp.https.address'].split(':')[1]
      nm_hosts = ctx.hosts_with_module 'ryba/hadoop/yarn_nm'
      if nm_hosts.length
        nm_ctx = ctx.hosts[nm_hosts[0]]
        require('../hadoop/yarn_nm').configure nm_ctx
        nm_webapp_port = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
        then nm_ctx.config.ryba.yarn.site['yarn.nodemanager.webapp.address'].split(':')[1]
        else nm_ctx.config.ryba.yarn.site['yarn.nodemanager.webapp.https.address'].split(':')[1]
      jhs_hosts = ctx.hosts_with_module 'ryba/hadoop/mapred_jhs'
      if jhs_hosts.length
        jhs_ctx = ctx.hosts[jhs_hosts[0]]
        require('../hadoop/mapred_jhs').configure jhs_ctx
        hs_webapp_port = jhs_ctx.config.ryba.mapred_site['mapreduce.jobhistory.webapp.address'].split(':')[1]
      jn_hosts = ctx.hosts_with_module 'ryba/hadoop/hdfs_jn'
      if jn_hosts.length
        jn_ctx = ctx.hosts[jn_hosts[0]]
        require('../hadoop/hdfs_jn').configure jn_ctx
        journalnode_port = jn_ctx.config.ryba.hdfs_site["dfs.journalnode.#{protocol}-address"].split(':')[1]
      datanode_port = hdfs_site["dfs.datanode.#{protocol}.address"].split(':')[1]
      hm_hosts = ctx.hosts_with_module 'ryba/hbase/master'
      hive_server_port = if hive_site['hive.server2.transport.mode'] is 'binary'
      then hive_site['hive.server2.thrift.port']
      else hive_site['hive.server2.thrift.http.port']
      # protocol = if hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      # shortname = ctx.hosts[active_nn_host].config.shortname
      # active_nn_port = ctx.config.ryba.ha_client_config["dfs.namenode.#{protocol}-address.#{nameservice}.#{shortname}"].split(':')[1]
      hostgroup_defs = {}
      for group, hosts of nagios.hostgroups
        hostgroup_defs[group] = if hosts.length then hosts else null
      ctx.render
        source: "#{__dirname}/../resources/nagios/templates/hadoop-services.cfg.j2"
        local_source: true
        destination: '/etc/nagios/objects/hadoop-services.cfg'
        context:
          hostgroup_defs: hostgroup_defs
          all_hosts: [] # Ambari agents
          nagios_lookup_daemon_str: '/usr/sbin/nagios'
          namenode_port: active_nn_port
          dfs_ha_enabled: not ctx.host_with_module 'ryba/hadoop/hdfs_snn'
          all_ping_ports: null # Ambari agent ports
          ganglia_port: ganglia.collector_port
          ganglia_collector_namenode_port: ganglia.nn_port
          ganglia_collector_hbase_port: ganglia.hm_port
          ganglia_collector_rm_port: ganglia.rm_port
          ganglia_collector_hs_port: ganglia.jhs_port
          snamenode_port: hdfs_site['dfs.namenode.secondary.http-address']?.split(':')[1]
          storm_ui_port: 0 # TODO Storm
          nimbus_port: 0 # TODO Storm
          drpc_port: 0 # TODO Storm
          storm_rest_api_port: 0 # TODO Storm
          supervisor_port: 0 # TODO Storm
          hadoop_ssl_enabled: protocol is 'https'
          nagios_keytab_path: nagios.keytab
          nagios_principal_name: nagios.principal
          kinit_path_local: nagios.kinit
          security_enabled: true
          nn_ha_host_port_map: nn_hosts_map
          namenode_host: nn_hosts
          nn_hosts_string: nn_hosts.join ' '
          dfs_namenode_checkpoint_period: hdfs_site['dfs.namenode.checkpoint.period'] or 21600
          dfs_namenode_checkpoint_txns: hdfs_site['dfs.namenode.checkpoint.txns'] or 1000000
          nn_metrics_property: 'FSNamesystem'
          rm_hosts_in_str: rm_hosts.join ','
          rm_port: rm_webapp_port
          nm_port: nm_webapp_port
          hs_port: hs_webapp_port
          journalnode_port: journalnode_port
          datanode_port: datanode_port
          clientPort: zookeeper_port
          hbase_rs_port: hbase_site['hbase.regionserver.info.port']
          hbase_master_port: hbase_site['hbase.master.info.port']
          hbase_master_hosts_in_str: hm_hosts.join ','
          hbase_master_hosts: hm_hosts
          hbase_master_rpc_port: hbase_site['hbase.master.port']
          hive_metastore_port: url.parse(hive_site['hive.metastore.uris']).port
          hive_server_port: hive_server_port
          oozie_server_port: url.parse(oozie_site['oozie.base.url']).port
          java64_home: ctx.config.java.java_home # Used by check_oozie_status.sh
          templeton_port: webhcat_site['templeton.port']
          falcon_port: 0 # TODO
          ahs_port: 0 # TODO
          hue_port: hue.ini.desktop.http.port
      , next

    module.exports.push name: 'Nagios # Commands', callback: (ctx, next) ->
      ctx.write
        source: "#{__dirname}/../resources/nagios/objects/hadoop-commands.cfg"
        local_source: true
        destination: '/etc/nagios/objects/hadoop-commands.cfg'
        write: [
          match: '@STATUS_DAT@'
          replace: '/var/nagios/status.dat'
        ]
      , next

## Module Dependencies

    path = require 'path'
    url = require 'url'
    glob = require 'glob'




