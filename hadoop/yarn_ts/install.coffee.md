
# YARN Timeline Server Install

The Timeline Server is a stand-alone server daemon and doesn't need to be
co-located with any other service.

    module.exports = header: 'YARN ATS Install', handler: ->
      {java} = @config
      {realm, hadoop_group, hadoop_metrics, core_site, hdfs, yarn, hadoop_libexec_dir} = @config.ryba
      {ssl, ssl_server, ssl_client, yarn} = @config.ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## Wait

      @call once: true, 'masson/core/krb5_client/wait'

## IPTables

| Service   | Port   | Proto     | Parameter                                  |
|-----------|------- |-----------|--------------------------------------------|
| timeline  | 10200  | tcp/http  | yarn.timeline-service.address              |
| timeline  | 8188   | tcp/http  | yarn.timeline-service.webapp.address       |
| timeline  | 8190   | tcp/https | yarn.timeline-service.webapp.https.address |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      [_, rpc_port] = yarn.site['yarn.timeline-service.address'].split ':'
      [_, http_port] = yarn.site['yarn.timeline-service.webapp.address'].split ':'
      [_, https_port] = yarn.site['yarn.timeline-service.webapp.https.address'].split ':'
      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: rpc_port, protocol: 'tcp', state: 'NEW', comment: "Yarn Timeserver RPC" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: http_port, protocol: 'tcp', state: 'NEW', comment: "Yarn Timeserver HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: https_port, protocol: 'tcp', state: 'NEW', comment: "Yarn Timeserver HTTPS" }
        ]
        if: @config.iptables.action is 'start'

## Service

Install the "hadoop-yarn-timelineserver" service, symlink the rc.d startup script
in "/etc/init.d/hadoop-hdfs-datanode" and define its startup strategy.

      @call header: 'Service', handler: (options) ->
        @service
          name: 'hadoop-yarn-timelineserver'
        @hdp_select
          name: 'hadoop-yarn-client' # Not checked
          name: 'hadoop-yarn-timelineserver'
        @service.init
          target: '/etc/init.d/hadoop-yarn-timelineserver'
          source: "#{__dirname}/../resources/hadoop-yarn-timelineserver.j2"
          local: true
          context: @config
          mode: 0o0755
        @system.tmpfs
          if: -> (options.store['mecano:system:type'] in ['redhat','centos']) and (options.store['mecano:system:release'][0] is '7')
          mount: "#{yarn.ats.pid_dir}"
          uid: yarn.user.name
          gid: hadoop_group.name
          perm: '0755'
        @system.execute
          cmd: "service hadoop-yarn-timelineserver restart"
          if: -> @status -4

# Layout

      @call header: 'Layout', handler: ->
        @system.mkdir
          target: "#{yarn.ats.conf_dir}"
        @system.mkdir
          target: "#{yarn.ats.pid_dir}"
          uid: yarn.user.name
          gid: hadoop_group.name
          mode: 0o755
        @system.mkdir
          target: "#{yarn.ats.log_dir}"
          uid: yarn.user.name
          gid: yarn.group.name
          parent: true
        @system.mkdir
          target: yarn.site['yarn.timeline-service.leveldb-timeline-store.path']
          uid: yarn.user.name
          gid: hadoop_group.name
          mode: 0o0750
          parent: true

## Configuration

Update the "yarn-site.xml" configuration file.

      @hconfigure
        header: 'Core Site'
        target: "#{yarn.ats.conf_dir}/core-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/core-site.xml"
        local_source: true
        properties: core_site
        backup: true
      @hconfigure
        header: 'HDFS Site'
        target: "#{yarn.ats.conf_dir}/hdfs-site.xml"
        properties: hdfs.site
        backup: true
      @hconfigure
        header: 'YARN Site'
        target: "#{yarn.ats.conf_dir}/yarn-site.xml"
        properties: yarn.site
        backup: true
      @file
        header: 'Log4j'
        target: "#{yarn.ats.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local_source: true
      @file.render
        target: "#{yarn.ats.conf_dir}/yarn-env.sh"
        source: "#{__dirname}/../resources/yarn-env.sh.j2"
        local_source: true
        context: #@config
          JAVA_HOME: java.java_home
          HADOOP_YARN_HOME: yarn.ats.home
          YARN_LOG_DIR: yarn.ats.log_dir
          YARN_PID_DIR: yarn.ats.pid_dir
          HADOOP_LIBEXEC_DIR: hadoop_libexec_dir
          YARN_HEAPSIZE: yarn.heapsize
          YARN_HISTORYSERVER_HEAPSIZE: yarn.ats.heapsize
          YARN_HISTORYSERVER_OPTS: yarn.ats.opts
          YARN_OPTS: yarn.opts
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o0755
        backup: true

Configure the "hadoop-metrics2.properties" to connect Hadoop to a Metrics collector like Ganglia or Graphite.

      @file.properties
        header: 'Metrics'
        target: "#{yarn.ats.conf_dir}/hadoop-metrics2.properties"
        content: hadoop_metrics.config
        backup: true

# HDFS Layout

See:

*   [YarnConfiguration](https://github.com/apache/hadoop/blob/trunk/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-api/src/main/java/org/apache/hadoop/yarn/conf/YarnConfiguration.java#L1425-L1426)
*   [FileSystemApplicationHistoryStore](https://github.com/apache/hadoop/blob/trunk/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-server/hadoop-yarn-server-applicationhistoryservice/src/main/java/org/apache/hadoop/yarn/server/applicationhistoryservice/FileSystemApplicationHistoryStore.java)

Note, this is not documented anywhere and might not be considered as a best practice.

      @call header: 'HDFS layout', timeout: -1, handler: ->
        return unless yarn.site['yarn.timeline-service.generic-application-history.store-class'] is "org.apache.hadoop.yarn.server.applicationhistoryservice.FileSystemApplicationHistoryStore"
        dir = yarn.site['yarn.timeline-service.fs-history-store.uri']
        @wait.execute
          cmd: mkcmd.hdfs @, "hdfs dfs -test -d #{path.dirname dir}"
        @system.execute
          cmd: mkcmd.hdfs @, """
          hdfs dfs -mkdir -p #{dir}
          hdfs dfs -chown #{yarn.user.name} #{dir}
          hdfs dfs -chmod 1777 #{dir}
          """
          unless_exec: "[[ hdfs dfs -d #{dir} ]]"

## SSL

      @call header: 'SSL', retry: 0, handler: ->
        ssl_client['ssl.client.truststore.location'] = "#{yarn.ats.conf_dir}/truststore"
        ssl_server['ssl.server.keystore.location'] = "#{yarn.ats.conf_dir}/keystore"
        ssl_server['ssl.server.truststore.location'] = "#{yarn.ats.conf_dir}/truststore"
        @hconfigure
          target: "#{yarn.ats.conf_dir}/ssl-server.xml"
          properties: ssl_server
        @hconfigure
          target: "#{yarn.ats.conf_dir}/ssl-client.xml"
          properties: ssl_client
        # Client: import certificate to all hosts
        @java.keystore_add
          keystore: ssl_client['ssl.client.truststore.location']
          storepass: ssl_client['ssl.client.truststore.password']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          local_source: true
        # Server: import certificates, private and public keys to hosts with a server
        @java.keystore_add
          keystore: ssl_server['ssl.server.keystore.location']
          storepass: ssl_server['ssl.server.keystore.password']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          key: "#{ssl.key}"
          cert: "#{ssl.cert}"
          keypass: ssl_server['ssl.server.keystore.keypassword']
          name: @config.shortname
          local_source: true
        @java.keystore_add
          keystore: ssl_server['ssl.server.keystore.location']
          storepass: ssl_server['ssl.server.keystore.password']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          local_source: true

## Kerberos

Create the Kerberos service principal by default in the form of
"ats/{host}@{realm}" and place its keytab inside
"/etc/security/keytabs/ats.service.keytab" with ownerships set to
"mapred:hadoop" and permissions set to "0600".

      @krb5.addprinc krb5,
        header: 'Kerberos'
        principal: yarn.site['yarn.timeline-service.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: yarn.site['yarn.timeline-service.keytab']
        uid: yarn.user.name
        gid: yarn.group.name
        mode: 0o0600

## Dependencies

    path = require 'path'
    mkcmd = require '../../lib/mkcmd'
