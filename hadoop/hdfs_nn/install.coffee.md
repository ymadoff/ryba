
# Hadoop HDFS NameNode Install

This implementation configure an HA HDFS cluster, using the [Quorum Journal Manager (QJM)](qjm)
feature  to share edit logs between the Active and Standby NameNodes. Hortonworks
provides [instructions to rollback a HA installation][rollback] that apply to Ambari.

Worth to investigate:

*   [RPC Congestion Control with FairCallQueue](https://issues.apache.org/jira/browse/HADOOP-9640)
*   [RPC fair share](https://issues.apache.org/jira/browse/HADOOP-10598)

[rollback]: http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.3/bk_Monitoring_Hadoop_Book/content/monitor-ha-undoing_2x.html

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs'
    module.exports.push 'ryba/lib/hconfigure'
    # module.exports.push require '../../lib/hdp_service'
    module.exports.push 'ryba/lib/hdp_select'

## Configuration

The NameNode doesn't define new configuration properties. However, it uses properties
define inside the "ryba/hadoop/hdfs" and "masson/core/nc" modules.

    # module.exports.push require('./index').configure

## IPTables

| Service    | Port | Proto  | Parameter                  |
|------------|------|--------|----------------------------|
| namenode  | 50070 | tcp    | dfs.namdnode.http-address  |
| namenode  | 50470 | tcp    | dfs.namenode.https-address |
| namenode  | 8020  | tcp    | fs.defaultFS               |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push header: 'HDFS NN # IPTables', handler: ->
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 50070, protocol: 'tcp', state: 'NEW', comment: "HDFS NN HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 50470, protocol: 'tcp', state: 'NEW', comment: "HDFS NN HTTPS" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8020, protocol: 'tcp', state: 'NEW', comment: "HDFS NN IPC" }
          # { chain: 'INPUT', jump: 'ACCEPT', dport: 8019, protocol: 'tcp', state: 'NEW', comment: "HDFS NN IPC" }
          # { chain: 'INPUT', jump: 'ACCEPT', dport: 9000, protocol: 'tcp', state: 'NEW', comment: "HDFS NN IPC" }
        ]
        if: @config.iptables.action is 'start'

## Service

Install the "hadoop-hdfs-namenode" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

    module.exports.push header: 'HDFS NN # Service', handler: ->
      @service
        name: 'hadoop-hdfs-namenode'
      @hdp_select
        name: 'hadoop-hdfs-client' # Not checked
        name: 'hadoop-hdfs-namenode'
      @render
        destination: '/etc/init.d/hadoop-hdfs-namenode'
        source: "#{__dirname}/../resources/hadoop-hfds-namenode"
        local_source: true
        context: @config
        mode: 0o0755
        unlink: true
      @execute
        cmd: "service hadoop-hdfs-namenode restart"
        if: -> @status -3

## Layout

Create the NameNode data and pid directories. The NameNode data is by defined in the
"/etc/hadoop/conf/hdfs-site.xml" file by the "dfs.namenode.name.dir" property. The pid
file is usually stored inside the "/var/run/hadoop-hdfs/hdfs" directory.

    module.exports.push header: 'HDFS NN # Layout', timeout: -1, handler: ->
      {hdfs, hadoop_group} = @config.ryba
      @mkdir
        destination: "#{hdfs.nn.conf_dir}"
      @mkdir
        destination: for dir in hdfs.nn.site['dfs.namenode.name.dir'].split ','
          if dir.indexOf('file://') is 0
          then dir.substr(7) else dir
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
        parent: true
      @mkdir
        destination: "#{hdfs.pid_dir.replace '$USER', hdfs.user.name}"
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
      @mkdir
        destination: "#{hdfs.log_dir}" #/#{hdfs.user.name}
        uid: hdfs.user.name
        gid: hdfs.group.name
        parent: true

## Configure

    module.exports.push header: 'HDFS NN # Configure', handler: ->
      {hdfs, core_site, hadoop_group, hadoop_metrics} = @config.ryba
      @hconfigure
        header: 'Core Site'
        destination: "#{hdfs.nn.conf_dir}/core-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/core-site.xml"
        local_default: true
        properties: merge {}, core_site, hdfs.nn.core_site
        backup: true
      @hconfigure
        destination: "#{hdfs.nn.conf_dir}/hdfs-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
        local_default: true
        properties: hdfs.nn.site
        uid: hdfs.user.name
        gid: hadoop_group.name
        backup: true

## Environment

Maintain the "hadoop-env.sh" file present in the HDP companion File.

The location for JSVC depends on the platform. The Hortonworks documentation
mentions "/usr/libexec/bigtop-utils" for RHEL/CentOS/Oracle Linux. While this is
correct for RHEL, it is installed in "/usr/lib/bigtop-utils" on my CentOS.
      
      @render
        header: 'Environment'
        destination: "#{hdfs.nn.conf_dir}/hadoop-env.sh"
        source: "#{__dirname}/../resources/hadoop-env.sh"
        local_source: true
        context: @config
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
        backup: true
        eof: true
      @write
        header: 'Log4j'
        destination: "#{hdfs.nn.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local_source: true

## Hadoop Metrics

Configure the "hadoop-metrics2.properties" to connect Hadoop to a Metrics collector like Ganglia or Graphite.

      @write_properties
        header: 'Metrics'
        destination: "#{hdfs.nn.conf_dir}/hadoop-metrics2.properties"
        content: hadoop_metrics.config
        backup: true

## SSL

    module.exports.push header: 'HDFS NN # SSL', retry: 0, handler: ->
      {ssl, ssl_server, ssl_client, hdfs} = @config.ryba
      ssl_client['ssl.client.truststore.location'] = "#{hdfs.nn.conf_dir}/truststore"
      ssl_server['ssl.server.keystore.location'] = "#{hdfs.nn.conf_dir}/keystore"
      ssl_server['ssl.server.truststore.location'] = "#{hdfs.nn.conf_dir}/truststore"
      @hconfigure
        destination: "#{hdfs.nn.conf_dir}/ssl-server.xml"
        properties: ssl_server
      @hconfigure
        destination: "#{hdfs.nn.conf_dir}/ssl-client.xml"
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

Create a service principal for this NameNode. The principal is named after
"nn/#{@config.host}@#{realm}".

    module.exports.push header: 'HDFS NN # Kerberos', handler: ->
      {realm, hadoop_group, hdfs} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: hdfs.nn.site['dfs.namenode.kerberos.principal'].replace '_HOST', @config.host
        keytab: hdfs.nn.site['dfs.namenode.keytab.file']
        randkey: true
        uid: hdfs.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        mode: 0o0600
        kadmin_server: admin_server

## Ulimit

Increase ulimit for the HFDS user. The HDP package create the following
files:

```bash
cat /etc/security/limits.d/hdfs.conf
hdfs   - nofile 32768
hdfs   - nproc  65536
```

The procedure follows [Kate Ting's recommandations][kate]. This is a cause
of error if you receive the message: 'Exception in thread "main" java.lang.OutOfMemoryError: unable to create new native thread'.

Also worth of interest are the [Pivotal recommandations][hawq] as well as the
[Greenplum recommandation from Nixus Technologies][greenplum], the
[MapR documentation][mapr] and [Hadoop Performance via Linux presentation][hpl].

Note, a user must re-login for those changes to be taken into account.

    module.exports.push header: 'HDFS NN # Ulimit', handler: ->
      {hdfs} = @config.ryba
      @system_limits
        user: hdfs.user.name
        nofile: hdfs.user.limits.nofile
        nproc: hdfs.user.limits.nproc

## Include/Exclude

The "dfs.hosts" property specifies the file that contains a list of hosts that
are permitted to connect to the namenode. The full pathname of the file must be
specified. If the value is empty, all hosts are permitted.

The "dfs.hosts.exclude" property specifies the file that contains a list of
hosts that are not permitted to connect to the namenode.  The full pathname of
the file must be specified.  If the value is empty, no hosts are excluded.

    module.exports.push header: 'HDFS NN # Include/Exclude', handler: ->
      {hdfs} = @config.ryba
      @write
        content: "#{hdfs.include.join '\n'}"
        destination: "#{hdfs.nn.site['dfs.hosts']}"
        eof: true
        backup: true
      @write
        content: "#{hdfs.exclude.join '\n'}"
        destination: "#{hdfs.nn.site['dfs.hosts.exclude']}"
        eof: true
        backup: true

## Slaves

The slaves file should contain the hostname of every machine in the cluster
which should start TaskTracker and DataNode daemons.

Helper scripts (described below) use this file in "/etc/hadoop/conf/slaves"
to run commands on many hosts at once. In order to use this functionality, ssh
trusts (via either passphraseless ssh or some other means, such as Kerberos)
must be established for the accounts used to run Hadoop.

    module.exports.push header: 'HDFS NN # Slaves', handler: ->
      {hdfs} = @config.ryba
      @write
        content: @contexts('ryba/hadoop/hdfs_dn').map((ctx) -> ctx.config.host).join '\n'
        destination: "#{hdfs.nn.conf_dir}/slaves"
        eof: true

## Format

Format the HDFS filesystem. This command is only run from the active NameNode and if
this NameNode isn't yet formated by detecting if the "current/VERSION" exists. The action
is only exected once all the JournalNodes are started. The NameNode is finally restarted
if the NameNode was formated.

    module.exports.push header: 'HDFS NN # Format', timeout: -1, modules: 'ryba/hadoop/hdfs_jn/wait', handler: ->
      {hdfs, active_nn_host, nameservice} = @config.ryba
      any_dfs_name_dir = hdfs.nn.site['dfs.namenode.name.dir'].split(',')[0]
      any_dfs_name_dir = any_dfs_name_dir.substr(7) if any_dfs_name_dir.indexOf('file://') is 0
      is_hdfs_ha = @hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      # For non HA mode
      @execute
        cmd: "su -l #{hdfs.user.name} -c \"hdfs --config '#{hdfs.nn.conf_dir}' namenode -format\""
        unless: is_hdfs_ha
        unless_exists: "#{any_dfs_name_dir}/current/VERSION"
      # For HA mode, on the leader namenode
      @execute
        cmd: "su -l #{hdfs.user.name} -c \"hdfs --config '#{hdfs.nn.conf_dir}' namenode -format -clusterId '#{nameservice}'\""
        if: is_hdfs_ha and active_nn_host is @config.host
        unless_exists: "#{any_dfs_name_dir}/current/VERSION"

## HA Init Standby NameNodes

Copy over the contents of the active NameNode metadata directories to an other,
unformatted NameNode. The command "hdfs namenode -bootstrapStandby" used for the transfer
is only executed on the standby NameNode.

    module.exports.push
      header: 'HDFS NN # HA Init Standby'
      timeout: -1
      if: -> @hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      unless: -> @config.host is @config.ryba.active_nn_host
      handler: ->
        {hdfs, active_nn_host} = @config.ryba
        @wait_connect
          host: active_nn_host
          port: 8020
        @execute
          cmd: "su -l #{hdfs.user.name} -c \"hdfs --config '#{hdfs.nn.conf_dir}' namenode -bootstrapStandby -nonInteractive\""
          code_skipped: 5

## Policy

By default the service-level authorization is disabled in hadoop, to enable that
we need to set/configure the hadoop.security.authorization to true in
${HADOOP_CONF_DIR}/core-site.xml

    module.exports.push header: 'Hadoop Core # Policy', handler: ->
      {core_site, hdfs, hadoop_policy} = @config.ryba
      @hconfigure
        destination: "#{hdfs.nn.conf_dir}/hadoop-policy.xml"
        default: "#{__dirname}/../../resources/core_hadoop/hadoop-policy.xml"
        local_default: true
        properties: hadoop_policy
        backup: true
        if: core_site['hadoop.security.authorization'] is 'true'
      @execute
        cmd: mkcmd.hdfs @, "service hadoop-hdfs-namenode status && hdfs --config '#{hdfs.nn.conf_dir}' dfsadmin -refreshServiceAcl"
        code_skipped: 3
        if: -> @status -1

## Dependencies

    mkcmd = require '../../lib/mkcmd'
    {merge} = require 'mecano/lib/misc'
