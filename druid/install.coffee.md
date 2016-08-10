
# Druid Install

    module.exports = header: 'Druid Install', handler: ->
      {druid, realm} = @config.ryba
      # krb5 = @config.krb5.etc_krb5_conf.realms[realm]

## Register

      # @register 'hdp_select', 'ryba/lib/hdp_select'
      @register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'

## IPTables

| Service   | Port       | Proto     | Parameter                   |
|-----------|------------|-----------|-----------------------------|
| druid Standalone Realtime    | 8084      | tcp/http  |  |
| druid Router    | 8088      | tcp/http  |  |
| druid Tranquility Server    | 8200      | tcp/http  |  |

Note, this hasnt been verified.

      # @iptables
      #   header: 'IPTables'
      #   rules: [
      #     { chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'tcp', state: 'NEW', comment: "Falcon Prism Local EndPoint" }
      #   ]
      #   if: @config.iptables.action is 'start'

## Users & Groups

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep druid
falcon:x:496:498:Falcon:/var/lib/falcon:/bin/bash
cat /etc/group | grep druid
falcon:x:498:falcon
```

      @group druid.group
      @user druid.user

## Packages

Download and unpack the release archive.

      @download
        header: 'Packages'
        source: "#{druid.source}"
        target: "/var/tmp/#{path.basename druid.source}"
      # TODO, could be improved
      # current implementation prevent any further attempt if download status is true and extract fails
      @extract
        source: "/var/tmp/#{path.basename druid.source}"
        target: '/opt'
        if: -> @status -1
      @link
        source: "/opt/druid-#{druid.version}"
        target: "#{druid.dir}"
      @execute
        cmd: """
        if [ $(stat -c "%U" /opt/druid-#{druid.version}) == '#{druid.user.name}' ]; then exit 3; fi
        chown -R #{druid.user.name}:#{druid.group.name} /opt/druid-#{druid.version}
        """
        code_skipped: 3

## Layout

Pid files are stored inside "/var/run/druid" by default.
Log files are stored inside "/var/log/druid" by default.

      @call header: 'Layout', handler: ->
        @mkdir
          target: "#{druid.pid_dir}"
          uid: "#{druid.user.name}"
          gid: "#{druid.group.name}"
          parent: true
        @link
          target: "#{druid.dir}/var/druid/pids"
          source: "#{druid.pid_dir}"
        @mkdir
          target: "#{druid.log_dir}"
          uid: "#{druid.user.name}"
          gid: "#{druid.group.name}"
          parent: true
        @link
          source: "#{druid.log_dir}"
          target: "#{druid.dir}/log"

## Configuration

Configure deep storage.

      # Get ZooKeeper Quorum
      zoo_ctxs = @contexts 'ryba/zookeeper/server', require('../zookeeper/server/configure').handler
      zookeeper_quorum = for zoo_ctx in zoo_ctxs
        "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.port}"
      @write.properties
        target: "/opt/druid-#{druid.version}/conf/druid/_common/common.runtime.properties"
        content:
          # Extensions
          # Note, Mysql extension isnt natively supported due to licensing issues
          'druid.extensions.loadList': '["druid-kafka-eight", "druid-s3-extensions", "druid-histogram", "druid-datasketches", "druid-lookups-cached-global"]' # "mysql-metadata-storage"
          # Logging
          'druid.startup.logging.logProperties': 'true'
          # Zookeeper
          'druid.zk.service.host': "#{zookeeper_quorum.join ','}"
          'druid.zk.paths.base': '/druid'
          # Metadata storage
          'druid.metadata.storage.type': 'derby'
          'druid.metadata.storage.connector.connectURI': "jdbc:derby://#{@config.host}:1527/var/druid/metadata.db;create=true"
          'druid.metadata.storage.connector.host': "#{@config.host}"
          'druid.metadata.storage.connector.port': '1527'
          # For MySQL:
          #druid.metadata.storage.type=mysql
          #druid.metadata.storage.connector.connectURI=jdbc:mysql://db.example.com:3306/druid
          #druid.metadata.storage.connector.user=...
          #druid.metadata.storage.connector.password=...
          # For PostgreSQL (make sure to additionally include the Postgres extension):
          #druid.metadata.storage.type=postgresql
          #druid.metadata.storage.connector.connectURI=jdbc:postgresql://db.example.com:5432/druid
          #druid.metadata.storage.connector.user=...
          #druid.metadata.storage.connector.password=...
          # Deep storage
          # Extension "druid-hdfs-storage" added to "loadList"
          'druid.storage.type': 'hdfs'
          'druid.storage.storageDirectory': '/apps/druid/segments'
          # Indexing service logs
          'druid.indexer.logs.type': 'hdfs'
          'druid.indexer.logs.directory': '/apps/druid/indexing-logs'
          # Service discovery
          'druid.selectors.indexing.serviceName': 'druid/overlord'
          'druid.selectors.coordinator.serviceName': 'druid/coordinator'
          # Monitoring
          'druid.monitoring.monitors': '["com.metamx.metrics.JvmMonitor"]'
          'druid.emitter': 'logging'
          'druid.emitter.logging.logLevel': 'info'
        backup: true
      @link
        source: '/etc/hadoop/conf/core-site.xml'
        target: "/opt/druid-#{druid.version}/conf/druid/_common/core-site.xml"
      @link
        source: '/etc/hadoop/conf/hdfs-site.xml'
        target: "/opt/druid-#{druid.version}/conf/druid/_common/hdfs-site.xml"
      @link
        source: '/etc/hadoop/conf/yarn-site.xml'
        target: "/opt/druid-#{druid.version}/conf/druid/_common/yarn-site.xml"
      @link
        source: '/etc/hadoop/conf/mapred-site.xml'
        target: "/opt/druid-#{druid.version}/conf/druid/_common/mapred-site.xml"
      @hdfs_mkdir
        target: '/apps/druid/segments'
        user: "#{druid.user.name}"
        group: "#{druid.group.name}"
        mode: 0o0640
        krb5_user: @config.ryba.hdfs.krb5_user
      @hdfs_mkdir
        target: '/apps/druid/indexing-logs'
        user: "#{druid.user.name}"
        group: "#{druid.group.name}"
        mode: 0o0640
        krb5_user: @config.ryba.hdfs.krb5_user

#       @call header: 'Layout', handler: ->
#         @mkdir
#           target: falcon.log_dir
#           uid: falcon.user
#           gid: falcon.group
#           parent: true
# 
# ## Environnement
# 
# Enrich the file "mapred-env.sh" present inside the Hadoop configuration
# directory with the location of the directory storing the process pid.
# 
# Templated properties are "ryba.mapred.heapsize" and "ryba.mapred.pid_dir".
# 
#       @render
#         header: 'Falcon Env'
#         target: "#{falcon.conf_dir}/falcon-env.sh"
#         source: "#{__dirname}/../resources/falcon-env.sh.j2"
#         context: @config
#         local_source: true
#         backup: true
# 
# ## Kerberos
# 
#       @krb5_addprinc krb5,
#         header: 'Kerberos'
#         principal: startup['*.falcon.service.authentication.kerberos.principal']#.replace '_HOST', @config.host
#         randkey: true
#         keytab: startup['*.falcon.service.authentication.kerberos.keytab']
#         uid: user.name
#         gid: group.name
# 
# ## HFDS Layout
# 
#       @call header: 'HFDS Layout', handler: ->
#         # status = user_owner = group_owner = null
#         # @execute
#         #   cmd: mkcmd.hdfs @, "hdfs dfs -stat '%g;%u;%n' /apps/falcon"
#         #   code_skipped: 1
#         # , (err, exists, stdout) ->
#         #   return next err if err
#         #   status = exists
#         #   [user_owner, group_owner, filename] = stdout.trim().split ';' if exists
#         # @call ->
#         #   @execute
#         #     cmd: mkcmd.hdfs @, 'hdfs dfs -mkdir /apps/falcon'
#         #     unless: -> status
#         #   @execute
#         #     cmd: mkcmd.hdfs @, "hdfs dfs -chown #{user.name} /apps/falcon"
#         #     if: not status or user.name isnt user_owner
#         #   @execute
#         #     cmd: mkcmd.hdfs @, "hdfs dfs -chgrp #{group.name} /apps/falcon"
#         #     if: not status or group.name isnt group_owner
#         @hdfs_mkdir
#           target: '/apps/falcon'
#           user: "#{user.name}"
#           group: "#{group.name}"
#           mode: 0o1777
#           krb5_user: @config.ryba.hdfs.krb5_user
#         @hdfs_mkdir
#           target: '/apps/data-mirroring'
#           user: "#{user.name}"
#           group: "#{group.name}"
#           mode: 0o0770
#           krb5_user: @config.ryba.hdfs.krb5_user
#         @execute
#           shy: true
#           cmd: """
#           hdfs dfs -copyFromLocal -f /usr/hdp/current/falcon-server/data-mirroring /apps
#           hdfs dfs -chown -R #{user.name}:#{group.name} /apps/data-mirroring
#           """
# 
# ## Runtime
# 
#     # module.exports.push header: 'Falcon # Runtime', handler: ->
#     #   # {conf_dir, runtime} = @config.ryba.falcon
#     #   # @write_ini
#     #   #   target: "#{conf_dir}/runtime.properties"
#     #   #   content: runtime
#     #   #   separator: '='
#     #   #   merge: true
#     #   #   backup: true
#     #   # , next
#     #   {conf_dir, runtime} = @config.ryba.falcon
#     #   write = for k, v of runtime
#     #     match: RegExp "^#{quote k}=.*$", 'mg'
#     #     replace: "#{k}=#{v}"
#     #   @write
#     #     target: "#{conf_dir}/runtime.properties"
#     #     write: write
#     #     backup: true
#     #     eof: true
#     #   , next
# 
# ## Configuration
# 
#       @write
#         header: 'Configuration startup'
#         target: "#{conf_dir}/startup.properties"
#         write: for k, v of startup
#           match: RegExp "^#{quote k}=.*$", 'mg'
#           replace: "#{k}=#{v}"
#         backup: true
#         eof: true
#       @write
#         header: 'Configuration runtime'
#         target: "#{conf_dir}/runtime.properties"
#         write: for k, v of runtime
#           match: RegExp "^#{quote k}=.*$", 'mg'
#           replace: "#{k}=#{v}"
#         backup: true
#         eof: true

## Dependencies

    path = require 'path'
    # url = require 'url'
    # quote = require 'regexp-quote'
    # mkcmd = require '../lib/mkcmd'
