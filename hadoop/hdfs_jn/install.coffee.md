# Hadoop HDFS JournalNode Install

It apply to a secured HDFS installation with Kerberos.

The JournalNode daemon is relatively lightweight, so these daemons may reasonably
be collocated on machines with other Hadoop daemons, for example NameNodes, the
JobTracker, or the YARN ResourceManager.

There must be at least 3 JournalNode daemons, since edit log modifications must
be written to a majority of JNs. To increase the number of failures a system
can tolerate, deploy an odd number of JNs because the system can tolerate at
most (N - 1) / 2 failures to continue to function normally.

    module.exports = header: 'HDFS JN', handler: ->
      {hdfs, hadoop_group, core_site, hadoop_metrics} = @config.ryba

## Register

      @register 'hconfigure', 'ryba/lib/hconfigure'
      @register 'hdp_select', 'ryba/lib/hdp_select'

## IPTables

| Service     | Port | Proto  | Parameter                                      |
|-------------|------|--------|------------------------------------------------|
| journalnode | 8485 | tcp    | hdp.hdfs.site['dfs.journalnode.rpc-address']   |
| journalnode | 8480 | tcp    | hdp.hdfs.site['dfs.journalnode.http-address']  |
| journalnode | 8481 | tcp    | hdp.hdfs.site['dfs.journalnode.https-address'] |

Note, "dfs.journalnode.rpc-address" is used by "dfs.namenode.shared.edits.dir".

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      rpc = hdfs.site['dfs.journalnode.rpc-address'].split(':')[1]
      http = hdfs.site['dfs.journalnode.http-address'].split(':')[1]
      https = hdfs.site['dfs.journalnode.https-address'].split(':')[1]
      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: rpc, protocol: 'tcp', state: 'NEW', comment: "HDFS JournalNode" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: http, protocol: 'tcp', state: 'NEW', comment: "HDFS JournalNode" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: https, protocol: 'tcp', state: 'NEW', comment: "HDFS JournalNode" }
        ]
        if: @config.iptables.action is 'start'

## Layout

The JournalNode data are stored inside the directory defined by the
"dfs.journalnode.edits.dir" property.

      @call header: 'Layout', handler: ->
        @mkdir
          destination: "#{hdfs.jn.conf_dir}"
        @mkdir
          destination: for dir in hdfs.site['dfs.journalnode.edits.dir'].split ','
            if dir.indexOf('file://') is 0
            then dir.substr(7) else dir
          uid: hdfs.user.name
          gid: hadoop_group.name
        @mkdir
          destination: "#{hdfs.pid_dir}"
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o0755
          parent: true
        @mkdir
          destination: "#{hdfs.log_dir}" #/#{hdfs.user.name}
          uid: hdfs.user.name
          gid: hdfs.group.name
          parent: true

## Service

Install the "hadoop-hdfs-journalnode" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

      @call header: 'Packages', timeout: -1, handler: ->
        @service
          name: 'hadoop-hdfs-journalnode'
        @hdp_select
          name: 'hadoop-hdfs-client' # Not checked
          name: 'hadoop-hdfs-journalnode'
        @render
          destination: '/etc/init.d/hadoop-hdfs-journalnode'
          source: "#{__dirname}/../resources/hadoop-hdfs-journalnode"
          local_source: true
          context: @config
          mode: 0o0755
          unlink: true
        @execute
          cmd: "service hadoop-hdfs-journalnode restart"
          if: -> @status -3

## Configure

Update the "hdfs-site.xml" file with the "dfs.journalnode.edits.dir" property.

Register the SPNEGO service principal in the form of "HTTP/{host}@{realm}" into
the "hdfs-site.xml" file. The impacted properties are
"dfs.journalnode.kerberos.internal.spnego.principal",
"dfs.journalnode.kerberos.principal" and "dfs.journalnode.keytab.file". The
SPNEGO tocken is stored inside the "/etc/security/keytabs/spnego.service.keytab"
keytab, also used by the NameNodes, DataNodes, ResourceManagers and
NodeManagers.

      @call header: 'HDFS JN # Configure', handler: ->
        @hconfigure
          header: 'Core Site'
          destination: "#{hdfs.jn.conf_dir}/core-site.xml"
          default: "#{__dirname}/../../resources/core_hadoop/core-site.xml"
          local_default: true
          properties: core_site
          backup: true
        @hconfigure
          destination: "#{hdfs.jn.conf_dir}/hdfs-site.xml"
          default: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
          local_default: true
          properties: hdfs.site
          uid: hdfs.user.name
          gid: hadoop_group.name
          backup: true
        @write
          header: 'Log4j'
          destination: "#{hdfs.jn.conf_dir}/log4j.properties"
          source: "#{__dirname}/../resources/log4j.properties"
          local_source: true

Maintain the "hadoop-env.sh" file present in the HDP companion File.

The location for JSVC depends on the platform. The Hortonworks documentation
mentions "/usr/libexec/bigtop-utils" for RHEL/CentOS/Oracle Linux. While this is
correct for RHEL, it is installed in "/usr/lib/bigtop-utils" on my CentOS.
      
        @render
          header: 'Environment'
          destination: "#{hdfs.jn.conf_dir}/hadoop-env.sh"
          source: "#{__dirname}/../resources/hadoop-env.sh.j2"
          local_source: true
          context: @config
          uid: hdfs.user.name
          gid: hadoop_group.name
          mode: 0o755
          backup: true
          eof: true

Configure the "hadoop-metrics2.properties" to connect Hadoop to a Metrics collector like Ganglia or Graphite.

        @write_properties
          header: 'Metrics'
          destination: "#{hdfs.jn.conf_dir}/hadoop-metrics2.properties"
          content: hadoop_metrics.config
          backup: true

## SSL

      @call header: 'HDFS JN # SSL', retry: 0, handler: ->
        {ssl, ssl_server, ssl_client, hdfs} = @config.ryba
        ssl_client['ssl.client.truststore.location'] = "#{hdfs.jn.conf_dir}/truststore"
        ssl_server['ssl.server.keystore.location'] = "#{hdfs.jn.conf_dir}/keystore"
        ssl_server['ssl.server.truststore.location'] = "#{hdfs.jn.conf_dir}/truststore"
        @hconfigure
          destination: "#{hdfs.jn.conf_dir}/ssl-server.xml"
          properties: ssl_server
        @hconfigure
          destination: "#{hdfs.jn.conf_dir}/ssl-client.xml"
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

## Dependencies

    mkcmd = require '../../lib/mkcmd'
