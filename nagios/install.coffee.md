
# Nagios Install


    # module.exports.push require('./index').configure

    module.exports = header: 'Nagios Install', handler: ->
      {nagios, realm, active_nn_host, core_site, hdfs} = @config.ryba
      {zookeeper, hbase, oozie, webhcat, ganglia, hue} = @config.ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]

## Kerberos

      @krb5.addprinc krb5,
        header: 'Kerberos'
        principal: nagios.principal
        randkey: true
        keytab: nagios.keytab
        uid: nagios.user.name
        gid: nagios.user.group
        mode: 0o600

## Users & Groups

```bash
cat /etc/passwd | grep nagios
nagios:x:2418:2418:nagios:/var/log/nagios:/bin/sh
cat /etc/group | grep nagios
nagios:x:2418:
nagiocmd:x:2419:apache
```

      @call header: 'Users & Groups', ->
        @system.group nagios.group
        @system.group nagios.groupcmd
        @system.user nagios.user

## Packages

      @call header: 'Packages', ->
        @service name: 'net-snmp'
        @service name: 'net-snmp-utils'
        @service name: 'php-pecl-json'
        @service name: 'wget'
        @service name: 'httpd'
        @service name: 'php'
        @service name: 'net-snmp-perl'
        @service name: 'perl-Net-SNMP'
        @service name: 'fping'
        @service name: 'nagios', startup: true
        @service name: 'nagios-plugins'
        @service name: 'nagios-www'
        @system.discover (err, status, os) ->
          @system.tmpfs
            if: -> (os.type in ['redhat','centos']) and (os.release[0] is '7')
            mount: '/var/run/nagios'
            uid: nagios.user.name
            gid: nagios.group.name
            perm: '0750'

## Layout

      @call header: 'Layout', ->
        @system.mkdir
          target: [
            '/var/nagios', '/var/log/nagios',
            '/var/log/nagios/spool/checkresults', '/var/run/nagios'
          ]
          uid: nagios.user.name
          gid: nagios.group.name
        @system.mkdir
          target: '/var/nagios/rw'
          uid: nagios.user.name
          gid: nagios.groupcmd.name
          mode: 0o2770

## Objects

      @call header: 'Objects', ->
        @file (
          for object in ['hadoop-commands', 'hadoop-hosts', 'nagios']
            source = if object is 'nagios'
            then 'nagios.cfg-centos'
            else "#{object}.cfg"
            source: "#{__dirname}/resources/objects/#{source}"
            local: true
            target: "/etc/nagios/objects/#{object}.cfg"
            uid: nagios.user.name
            gid: nagios.group.name
            mode: 0o0644
            unless_exists: !nagios.overwrite
        )

## Plugins

      @call header: 'Plugins', (_, callback) ->
        {user, group, plugin_dir} = @config.ryba.nagios
        glob "#{__dirname}/resources/plugins/*", (err, plugins) =>
          return callback err if err
          @file (
            for plugin in plugins
              plugin = path.basename plugin
              source: "#{__dirname}/resources/plugins/#{plugin}"
              local: true
              target: "#{plugin_dir}/#{plugin}"
              uid: user.name
              gid: group.name
              mode: 0o0775
          )
          @then callback

## WebUI Users & Groups

### Password

      @call
        header: 'WebUI Users htpasswd'
        if: -> Object.getOwnPropertyNames(@config.ryba.nagios.users).length > 0
      , ->
        for name, user of @config.ryba.nagios.users
          @system.execute
            cmd: """
            if [ -e /etc/nagios/htpasswd.users ]; then
              hash=`cat /etc/nagios/htpasswd.users 2>/dev/null | grep #{name}: | sed 's/.*:\\(.*\\)/\\1/'`
              salt=`echo $hash | sed 's/\\(.\\{2\\}\\).*/\\1/'`
              if [ "$salt" != "" ]; then
                expect=`openssl passwd -crypt -salt $salt #{user.password} 2>/dev/null`
                if [ "$hash" == "$expect" ]; then exit 3; fi
              fi
              htpasswd -b /etc/nagios/htpasswd.users #{name} #{user.password}
            else
              htpasswd -c -b /etc/nagios/htpasswd.users #{name} #{user.password}
            fi
            """
            code_skipped: 3

### Users Configuration

      @call header: 'WebUI Users & Groups', ->
        {users, groups} = @config.ryba.nagios
        @file.render
          source: "#{__dirname}/resources/templates/contacts.cfg.j2"
          local: true
          target: '/etc/nagios/objects/contacts.cfg'
          context:
            users: users
            groups: groups

## Configuration

      @call header: 'Configuration', ->
        {user, group, plugin_dir} = @config.ryba.nagios
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
        @file
          target: '/etc/nagios/nagios.cfg'
          write: write
          eof: true
        @file
          target: '/etc/nagios/resource.cfg'
          match: /^\$USER1\$=.*$/mg
          replace: "$USER1$=#{plugin_dir}"

      @call header: 'Hosts', ->
        {user, group} = @config.ryba.nagios
        content = for host of @config.servers
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
        @file
          target: '/etc/nagios/objects/hadoop-hosts.cfg'
          content: content.join '\n'
          eof: true

## Nagios # Host Groups

The following command list all the referenced host groups:

```
cat /etc/nagios/objects/hadoop-services.cfg | grep hostgroup_name
```

      @call header: 'Host Groups', ->
        {nagios} = @config.ryba
        hostgroup_defs = {}
        for group, hosts of nagios.hostgroups
          hostgroup_defs[group] = if hosts.length then hosts else null
        @file.render
          source: "#{__dirname}/resources/templates/hadoop-hostgroups.cfg.j2"
          local: true
          target: '/etc/nagios/objects/hadoop-hostgroups.cfg'
          context:
            all_hosts: Object.keys @config.servers
            hostgroup_defs: hostgroup_defs

      @call header: 'Services Groups', ->
        {nagios} = @config.ryba
        hostgroup_defs = {}
        for group, hosts of nagios.hostgroups
          hostgroup_defs[group] = if hosts.length then hosts else null
        @file.render
          source: "#{__dirname}/resources/templates/hadoop-servicegroups.cfg.j2"
          local: true
          target: '/etc/nagios/objects/hadoop-servicegroups.cfg'
          context:
            hostgroup_defs: hostgroup_defs

## Services

        protocol = if hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
        # HDFS NameNode
        nn_hosts = @hosts_with_module 'ryba/hadoop/hdfs_nn'
        nn_hosts_map = {} # fqdn to port
        active_nn_port = null
        nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn', require('../hadoop/hdfs_nn/configure').handler
        if nn_ctxs.length is 1
          [nn_ctx] = nn_ctxs
          u = url.parse nn_ctx.config.ryba.core_site['fs.defaultFS']
          nn_hosts_map[u.hostname] = u.port
          active_nn_port = u.port
        else
          for nn_ctx in nn_ctxs
            protocol = if nn_ctx.config.ryba.hdfs.nn.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
            shortname = nn_ctx.config.shortname
            nameservice = nn_ctx.config.ryba.nameservice
            nn_host = @config.ryba.hdfs.site["dfs.namenode.#{protocol}-address.#{nameservice}.#{shortname}"].split(':')
            nn_hosts_map[nn_host[0]] = nn_host[1]
            active_nn_port = nn_host[1] if nn_ctx.config.host is active_nn_host
        # HDFS Secondary NameNode
        [snn_ctx] = @contexts 'ryba/hadoop/hdfs_snn'#, require('../hadoop/hdfs_snn').configure
        # YARN ResourceManager
        rm_ctxs = @contexts 'ryba/hadoop/yarn_rm'#, require('../hadoop/yarn_rm').configure
        rm_hosts = rm_ctxs.map (rm_ctx) -> rm_ctx.config.host
        # Get RM UI port for both HA and non-HA
        rm_site = rm_ctxs[0].config.ryba.yarn.rm.site
        id = if rm_ctxs.length > 1 then ".#{rm_site['yarn.resourcemanager.ha.id']}" else ''
        rm_webapp_port = if rm_site['yarn.http.policy'] is 'HTTP_ONLY'
        then rm_site["yarn.resourcemanager.webapp.address#{id}"].split(':')[1]
        else rm_site["yarn.resourcemanager.webapp.https.address#{id}"].split(':')[1]
        # YARN NodeManager
        nm_ctxs = @contexts 'ryba/hadoop/yarn_nm'#, require('../hadoop/yarn_nm').configure
        if nm_ctxs.length
          nm_webapp_port = if nm_ctxs[0].config.ryba.yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
          then nm_ctxs[0].config.ryba.yarn.site['yarn.nodemanager.webapp.address'].split(':')[1]
          else nm_ctxs[0].config.ryba.yarn.site['yarn.nodemanager.webapp.https.address'].split(':')[1]
        # MapReduce JobHistoryServer
        jhs_ctxs = @contexts 'ryba/hadoop/mapred_jhs'#, require('../hadoop/mapred_jhs').configure
        if jhs_ctxs.length
          hs_webapp_port = jhs_ctxs[0].config.ryba.mapred.site['mapreduce.jobhistory.webapp.address'].split(':')[1]
        # HDFS JournalNodes
        jn_ctxs = @contexts 'ryba/hadoop/hdfs_jn'#, require('../hadoop/hdfs_jn').configure
        if jn_ctxs.length
          journalnode_port = jn_ctxs[0].config.ryba.hdfs.site["dfs.journalnode.#{protocol}-address"].split(':')[1]
        # HDFS Datanodes
        [dn_ctx] = @contexts 'ryba/hadoop/hdfs_dn'#, require('../hadoop/hdfs_dn').configure
        dn_protocol = if dn_ctx.config.ryba.hdfs.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
        dn_port = dn_ctx.config.ryba.hdfs.site["dfs.datanode.#{protocol}.address"].split(':')[1]
        # HBase
        hm_ctxs = @contexts 'ryba/hbase/master', require('../hbase/master/configure').handler
        hrs_ctxs = @contexts 'ryba/hbase/regionserver', require('../hbase/regionserver/configure').handler
        # Hive
        hcat_ctxs = @contexts 'ryba/hive/hcatalog'#, require('../hive/hcatalog').configure
        hs2_ctxs = @contexts 'ryba/hive/server2'#, require('../hive/server2').configure
        hs2_port = if hs2_ctxs[0].config.ryba.hive.site['hive.server2.transport.mode'] is 'binary'
        then 'hive.server2.thrift.port'
        else 'hive.server2.thrift.http.port'
        hs2_port = hs2_ctxs[0].config.ryba.hive.site[hs2_port]
        hostgroup_defs = {}
        for group, hosts of nagios.hostgroups
          hostgroup_defs[group] = if hosts.length then hosts else null
        @file.render
          header: 'Services'
          source: "#{__dirname}/resources/templates/hadoop-services.cfg.j2"
          local: true
          target: '/etc/nagios/objects/hadoop-services.cfg'
          context:
            hostgroup_defs: hostgroup_defs
            all_hosts: [] # Ambari agents
            nagios_lookup_daemon_str: '/usr/sbin/nagios'
            namenode_port: active_nn_port
            dfs_ha_enabled: not @host_with_module 'ryba/hadoop/hdfs_snn'
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
            nagios_keytab_path: nagios.keytab
            nagios_principal_name: nagios.principal
            kinit_path_local: nagios.kinit
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
            hbase_rs_port: hrs_ctxs[0].config.ryba.hbase.rs.site['hbase.regionserver.info.port']
            hbase_master_port: hm_ctxs[0].config.ryba.hbase.master.site['hbase.master.info.port']
            hbase_master_hosts_in_str: hm_ctxs.map( (hm_ctx) -> hm_ctx.config.host ).join ','
            hbase_master_hosts: hm_ctxs.map( (hm_ctx) -> hm_ctx.config.host )
            hbase_master_rpc_port: hm_ctxs[0].config.ryba.hbase.master.site['hbase.master.port']
            hive_metastore_port: url.parse(hcat_ctxs[0].config.ryba.hive.site['hive.metastore.uris'].split(',')[0]).port
            hive_server_port: hs2_port
            oozie_url: oozie.site['oozie.base.url']
            java64_home: @config.java.java_home # Used by check_oozie_status.sh
            templeton_port: webhcat.site['templeton.port']
            falcon_port: 0 # TODO
            ahs_port: 0 # TODO
            hue_port: parseInt hue.ini.desktop['http_port']

## Commands

      @file
        header: 'Commands'
        source: "#{__dirname}/resources/objects/hadoop-commands.cfg"
        local: true
        target: '/etc/nagios/objects/hadoop-commands.cfg'
        write: [
          match: '@STATUS_DAT@'
          replace: '/var/nagios/status.dat'
        ]

## Dependencies

    path = require 'path'
    url = require 'url'
    glob = require 'glob'
    each = require 'each'
