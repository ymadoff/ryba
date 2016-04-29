
# YARN Timeline Server Install

The Timeline Server is a stand-alone server daemon and doesn't need to be
co-located with any other service.

    module.exports = header: 'YARN ATS Install', handler: ->
      {realm, hadoop_group, hadoop_metrics, core_site, hdfs, yarn} = @config.ryba
      {ssl, ssl_server, ssl_client, yarn} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]

## Register

      @register 'hconfigure', 'ryba/lib/hconfigure'
      @register 'hdp_select', 'ryba/lib/hdp_select'

## IPTables

| Service   | Port       | Proto     | Parameter                                  |
|-----------|------------|-----------|--------------------------------------------|
| timeline  | 10200      | tcp/http  | yarn.timeline-service.address              |
| timeline  | 8188 | tcp/http  | yarn.timeline-service.webapp.address       |
| timeline  | 8190      | tcp/https | yarn.timeline-service.webapp.https.address |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      [_, rpc_port] = yarn.site['yarn.timeline-service.address'].split ':'
      [_, http_port] = yarn.site['yarn.timeline-service.webapp.address'].split ':'
      [_, https_port] = yarn.site['yarn.timeline-service.webapp.https.address'].split ':'
      @iptables
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

      @call header: 'Service', handler: ->
        @service
          name: 'hadoop-yarn-timelineserver'
        @hdp_select
          name: 'hadoop-yarn-client' # Not checked
          name: 'hadoop-yarn-timelineserver'
        @render
          destination: '/etc/init.d/hadoop-yarn-timelineserver'
          source: "#{__dirname}/../resources/hadoop-yarn-timelineserver"
          local_source: true
          context: @config
          mode: 0o0755
          unlink: true
        @execute
          cmd: "service hadoop-yarn-timelineserver restart"
          if: -> @status -3

# Layout

      @call header: 'Layout', handler: ->
        @mkdir
          destination: "#{yarn.ats.conf_dir}"
        @mkdir
          destination: "#{yarn.pid_dir}"
          uid: yarn.user.name
          gid: hadoop_group.name
          mode: 0o755
        @mkdir
          destination: "#{yarn.log_dir}"
          uid: yarn.user.name
          gid: yarn.group.name
          parent: true
        @mkdir
          destination: yarn.site['yarn.timeline-service.leveldb-timeline-store.path']
          uid: yarn.user.name
          gid: hadoop_group.name
          mode: 0o0750
          parent: true

## Configuration

Update the "yarn-site.xml" configuration file.

      @hconfigure
        header: 'Core Site'
        destination: "#{yarn.ats.conf_dir}/core-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/core-site.xml"
        local_default: true
        properties: core_site
        backup: true
      @hconfigure
        header: 'HDFS Site'
        destination: "#{yarn.ats.conf_dir}/hdfs-site.xml"
        properties: hdfs.site
        backup: true
      @hconfigure
        header: 'YARN Site'
        destination: "#{yarn.ats.conf_dir}/yarn-site.xml"
        properties: yarn.site
        backup: true
      @write
        header: 'Log4j'
        destination: "#{yarn.ats.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local_source: true
      @render
        destination: "#{yarn.ats.conf_dir}/yarn-env.sh"
        source: "#{__dirname}/../resources/yarn-env.sh.j2"
        local_source: true
        context: @config
        uid: yarn.user.name
        gid: hadoop_group.name
        mode: 0o0755
        backup: true

Configure the "hadoop-metrics2.properties" to connect Hadoop to a Metrics collector like Ganglia or Graphite.

      @write_properties
        header: 'Metrics'
        destination: "#{yarn.ats.conf_dir}/hadoop-metrics2.properties"
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
        @wait_execute
          cmd: mkcmd.hdfs @, "hdfs dfs -test -d #{path.dirname dir}"
        @execute
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
          destination: "#{yarn.ats.conf_dir}/ssl-server.xml"
          properties: ssl_server
        @hconfigure
          destination: "#{yarn.ats.conf_dir}/ssl-client.xml"
          properties: ssl_client
        # Client: import certificate to all hosts
        @java_keystore_add
          keystore: ssl_client['ssl.client.truststore.location']
          storepass: ssl_client['ssl.client.truststore.password']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          local_source: true
        # Server: import certificates, private and public keys to hosts with a server
        @java_keystore_add
          keystore: ssl_server['ssl.server.keystore.location']
          storepass: ssl_server['ssl.server.keystore.password']
          caname: "hadoop_root_ca"
          cacert: "#{ssl.cacert}"
          key: "#{ssl.key}"
          cert: "#{ssl.cert}"
          keypass: ssl_server['ssl.server.keystore.keypassword']
          name: @config.shortname
          local_source: true
        @java_keystore_add
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

      # module.exports.push 'ryba/hadoop/hdfs_nn/wait'
      # module.exports.push 'ryba/hadoop/hdfs_client/install'
      @krb5_addprinc
        header: 'Kerberos'
        principal: yarn.site['yarn.timeline-service.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: yarn.site['yarn.timeline-service.keytab']
        uid: yarn.user.name
        gid: yarn.group.name
        mode: 0o0600
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

## Dependencies

    path = require 'path'
    mkcmd = require '../../lib/mkcmd'
