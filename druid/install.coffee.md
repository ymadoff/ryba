
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
| Druid Standalone Realtime    | 8084      | tcp/http  |  |
| Druid Router    | 8088      | tcp/http  |  |

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
druid:x:2435:2435:druid User:/var/lib/druid:/bin/bash
cat /etc/group | grep druid
druid:x:2435:
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

## Dependencies

    path = require 'path'
