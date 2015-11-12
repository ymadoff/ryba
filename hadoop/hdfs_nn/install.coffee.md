
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

    module.exports.push name: 'HDFS NN # IPTables', handler: ->
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

    module.exports.push name: 'HDFS NN # Service', handler: ->
      @service
        name: 'hadoop-hdfs-namenode'
      @hdp_select
        name: 'hadoop-hdfs-client' # Not checked
        name: 'hadoop-hdfs-namenode'
      @write
        source: "#{__dirname}/../resources/hadoop-hfds-namenode"
        local_source: true
        destination: '/etc/init.d/hadoop-hdfs-namenode'
        mode: 0o0755
        unlink: true
      @execute
        cmd: "service hadoop-hdfs-namenode restart"
        if: -> @status -3

## Layout

Create the NameNode data and pid directories. The NameNode data is by defined in the
"/etc/hadoop/conf/hdfs-site.xml" file by the "dfs.namenode.name.dir" property. The pid
file is usually stored inside the "/var/run/hadoop-hdfs/hdfs" directory.

    module.exports.push name: 'HDFS NN # Layout', timeout: -1, handler: ->
      {hdfs, hadoop_group} = @config.ryba
      pid_dir = hdfs.pid_dir.replace '$USER', hdfs.user.name
      @mkdir
        destination: for dir in hdfs.site['dfs.namenode.name.dir'].split ','
          if dir.indexOf('file://') is 0
          then dir.substr(7) else dir
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
        parent: true
      @mkdir
        destination: "#{pid_dir}"
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755

## Kerberos

Create a service principal for this NameNode. The principal is named after
"nn/#{@config.host}@#{realm}".

    module.exports.push name: 'HDFS NN # Kerberos', handler: ->
      {realm, hadoop_group, hdfs} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: hdfs.site['dfs.namenode.kerberos.principal'].replace '_HOST', @config.host
        keytab: hdfs.site['dfs.namenode.keytab.file']
        randkey: true
        uid: hdfs.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        mode: 0o0600
        kadmin_server: admin_server

## Opts

Environment passed to the NameNode before it starts.

    module.exports.push name: 'HDFS NN # Opts', handler: ->
      {hadoop_conf_dir, hdfs} = @config.ryba
      @write
        destination: "#{hadoop_conf_dir}/hadoop-env.sh"
        match: /^export HADOOP_NAMENODE_OPTS="(.*) \$\{HADOOP_NAMENODE_OPTS\}" # RYBA CONF ".*?", DONT OVEWRITE/mg
        replace: "export HADOOP_NAMENODE_OPTS=\"#{hdfs.namenode_opts} ${HADOOP_NAMENODE_OPTS}\" # RYBA CONF \"ryba.hdfs.namenode_opts\", DONT OVEWRITE"
        before: /^export HADOOP_NAMENODE_OPTS=".*"$/mg
        backup: true

## Configure

    module.exports.push name: 'HDFS NN # Configure', handler: ->
      {hdfs, hadoop_conf_dir, hadoop_group} = @config.ryba
      @hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
        local_default: true
        properties: hdfs.site
        uid: hdfs.user.name
        gid: hadoop_group.name
        merge: true
        backup: true

## Include/Exclude

The "dfs.hosts" property specifies the file that contains a list of hosts that
are permitted to connect to the namenode. The full pathname of the file must be
specified. If the value is empty, all hosts are permitted.

The "dfs.hosts.exclude" property specifies the file that contains a list of
hosts that are not permitted to connect to the namenode.  The full pathname of
the file must be specified.  If the value is empty, no hosts are excluded.

    module.exports.push name: 'HDFS NN # Include/Exclude', handler: ->
      {hdfs} = @config.ryba
      @write
        content: "#{hdfs.include.join '\n'}"
        destination: "#{hdfs.site['dfs.hosts']}"
        eof: true
        backup: true
      @write
        content: "#{hdfs.exclude.join '\n'}"
        destination: "#{hdfs.site['dfs.hosts.exclude']}"
        eof: true
        backup: true

## Slaves

The slaves file should contain the hostname of every machine in the cluster
which should start TaskTracker and DataNode daemons.

Helper scripts (described below) use this file in "/etc/hadoop/conf/slaves"
to run commands on many hosts at once. In order to use this functionality, ssh
trusts (via either passphraseless ssh or some other means, such as Kerberos)
must be established for the accounts used to run Hadoop.

    module.exports.push name: 'HDFS NN # Slaves', handler: ->
      {hadoop_conf_dir} = @config.ryba
      datanodes = @hosts_with_module 'ryba/hadoop/hdfs_dn'
      @write
        content: "#{datanodes.join '\n'}"
        destination: "#{hadoop_conf_dir}/slaves"
        eof: true

## Format

Format the HDFS filesystem. This command is only run from the active NameNode and if
this NameNode isn't yet formated by detecting if the "current/VERSION" exists. The action
is only exected once all the JournalNodes are started. The NameNode is finally restarted
if the NameNode was formated.

    module.exports.push name: 'HDFS NN # Format', timeout: -1, modules: 'ryba/hadoop/hdfs_jn/wait', handler: ->
      {hdfs, active_nn_host, nameservice} = @config.ryba
      any_dfs_name_dir = hdfs.site['dfs.namenode.name.dir'].split(',')[0]
      any_dfs_name_dir = any_dfs_name_dir.substr(7) if any_dfs_name_dir.indexOf('file://') is 0
      is_hdfs_ha = @hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      # For non HA mode
      @execute
        cmd: "su -l #{hdfs.user.name} -c \"hdfs namenode -format\""
        unless: is_hdfs_ha
        unless_exists: "#{any_dfs_name_dir}/current/VERSION"
      # For HA mode, on the leader namenode
      @execute
        cmd: "su -l #{hdfs.user.name} -c \"hdfs namenode -format -clusterId #{nameservice}\""
        if: is_hdfs_ha and active_nn_host is @config.host
        unless_exists: "#{any_dfs_name_dir}/current/VERSION"

## HA Init Standby NameNodes

Copy over the contents of the active NameNode metadata directories to an other,
unformatted NameNode. The command "hdfs namenode -bootstrapStandby" used for the transfer
is only executed on the standby NameNode.

    module.exports.push
      name: 'HDFS NN # HA Init Standby'
      timeout: -1
      if: -> @hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      unless: -> @config.host is @config.ryba.active_nn_host
      handler: ->
        {hdfs, active_nn_host} = @config.ryba
        # return next() unless @hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
        # return next() if @config.host is active_nn_host
        @wait_connect
          host: active_nn_host
          port: 8020
        @execute
          cmd: "su -l #{hdfs.user.name} -c \"hdfs namenode -bootstrapStandby -nonInteractive\""
          code_skipped: 5

## Dependencies

    mkcmd = require '../../lib/mkcmd'
