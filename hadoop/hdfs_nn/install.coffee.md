
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
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../../lib/hdp_service'

## Configuration

The NameNode doesn't define new configuration properties. However, it uses properties
define inside the "ryba/hadoop/hdfs" and "masson/core/nc" modules.

    module.exports.push require('./index').configure

## IPTables

| Service    | Port | Proto  | Parameter                  |
|------------|------|--------|----------------------------|
| namenode  | 50070 | tcp    | dfs.namdnode.http-address  |
| namenode  | 50470 | tcp    | dfs.namenode.https-address |
| namenode  | 8020  | tcp    | fs.defaultFS               |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'HDFS NN # IPTables', handler: (ctx, next) ->
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 50070, protocol: 'tcp', state: 'NEW', comment: "HDFS NN HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 50470, protocol: 'tcp', state: 'NEW', comment: "HDFS NN HTTPS" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8020, protocol: 'tcp', state: 'NEW', comment: "HDFS NN IPC" }
          # { chain: 'INPUT', jump: 'ACCEPT', dport: 8019, protocol: 'tcp', state: 'NEW', comment: "HDFS NN IPC" }
          # { chain: 'INPUT', jump: 'ACCEPT', dport: 9000, protocol: 'tcp', state: 'NEW', comment: "HDFS NN IPC" }
        ]
        if: ctx.config.iptables.action is 'start'
      .then next

## Service

Install the "hadoop-hdfs-namenode" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

    module.exports.push name: 'HDFS NN # Service', handler: (ctx, next) ->
      ctx
      .hdp_service
        name: 'hadoop-hdfs-namenode'
      .then next

## Layout

Create the NameNode data and pid directories. The NameNode data is by defined in the
"/etc/hadoop/conf/hdfs-site.xml" file by the "dfs.namenode.name.dir" property. The pid
file is usually stored inside the "/var/run/hadoop-hdfs/hdfs" directory.

    module.exports.push name: 'HDFS NN # Layout', timeout: -1, handler: (ctx, next) ->
      {hdfs, hadoop_group} = ctx.config.ryba
      pid_dir = hdfs.pid_dir.replace '$USER', hdfs.user.name
      ctx
      .mkdir
        destination: hdfs.site['dfs.namenode.name.dir'].split ','
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
        parent: true
      .mkdir
        destination: "#{pid_dir}"
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
      .then next

## Kerberos

Create a service principal for this NameNode. The principal is named after
"nn/#{ctx.config.host}@#{realm}".

    module.exports.push name: 'HDFS NN # Kerberos', handler: (ctx, next) ->
      {realm, hadoop_group, hdfs} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: hdfs.site['dfs.namenode.kerberos.principal'].replace '_HOST', ctx.config.host
        keytab: hdfs.site['dfs.namenode.keytab.file']
        randkey: true
        uid: hdfs.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        mode: 0o0600
        kadmin_server: admin_server
      .then next

## Opts

Environment passed to the NameNode before it starts.

    module.exports.push name: 'HDFS NN # Opts', handler: (ctx, next) ->
      {hadoop_conf_dir, hdfs} = ctx.config.ryba
      ctx.write
        destination: "#{hadoop_conf_dir}/hadoop-env.sh"
        match: /^export HADOOP_NAMENODE_OPTS="(.*) \$\{HADOOP_NAMENODE_OPTS\}" # RYBA CONF ".*?", DONT OVEWRITE/mg
        replace: "export HADOOP_NAMENODE_OPTS=\"#{hdfs.namenode_opts} ${HADOOP_NAMENODE_OPTS}\" # RYBA CONF \"ryba.hdfs.namenode_opts\", DONT OVEWRITE"
        before: /^export HADOOP_NAMENODE_OPTS=".*"$/mg
        backup: true
      .then next

## Configure

    module.exports.push name: 'HDFS NN # Configure', handler: (ctx, next) ->
      {hdfs, hadoop_conf_dir, hadoop_group} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
        local_default: true
        properties: hdfs.site
        uid: hdfs.user.name
        gid: hadoop_group.name
        merge: true
        backup: true
      .then next

## Slaves

The conf/slaves file should contain the hostname of every machine
in the cluster which should start TaskTracker and DataNode daemons.

    module.exports.push name: 'HDFS NN # Slaves', handler: (ctx, next) ->
      {hadoop_conf_dir} = ctx.config.ryba
      datanodes = ctx.hosts_with_module 'ryba/hadoop/hdfs_dn'
      ctx.write
        content: "#{datanodes.join '\n'}"
        destination: "#{hadoop_conf_dir}/slaves"
        eof: true
      .then next

## Format

Format the HDFS filesystem. This command is only run from the active NameNode and if
this NameNode isn't yet formated by detecting if the "current/VERSION" exists. The action
is only exected once all the JournalNodes are started. The NameNode is finally restarted
if the NameNode was formated.

    module.exports.push name: 'HDFS NN # Format', timeout: -1, modules: 'ryba/hadoop/hdfs_jn/wait', handler: (ctx, next) ->
      {hdfs, active_nn_host, nameservice} = ctx.config.ryba
      any_dfs_name_dir = hdfs.site['dfs.namenode.name.dir'].split(',')[0]
      is_hdfs_ha = ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      ctx
      # For non HA mode
      .execute
        cmd: "su -l #{hdfs.user.name} -c \"hdfs namenode -format\""
        not_if: is_hdfs_ha
        not_if_exists: "#{any_dfs_name_dir}/current/VERSION"
      # For HA mode, on the leader namenode
      .execute
        cmd: "su -l #{hdfs.user.name} -c \"hdfs namenode -format -clusterId #{nameservice}\""
        if: is_hdfs_ha and active_nn_host is ctx.config.host
        not_if_exists: "#{any_dfs_name_dir}/current/VERSION"
      .then next

## HA Init Standby NameNodes

Copy over the contents of the active NameNode metadata directories to an other,
unformatted NameNode. The command "hdfs namenode -bootstrapStandby" used for the transfer
is only executed on a non active NameNode.

    module.exports.push name: 'HDFS NN # HA Init Standby', timeout: -1, handler: (ctx, next) ->
      {hdfs, active_nn_host} = ctx.config.ryba
      return next() unless ctx.hosts_with_module('ryba/hadoop/hdfs_nn').length > 1
      return next() if ctx.config.host is active_nn_host
      ctx.waitIsOpen active_nn_host, 8020, (err) ->
        return next err if err
        ctx.execute
          cmd: "su -l #{hdfs.user.name} -c \"hdfs namenode -bootstrapStandby -nonInteractive\""
          code_skipped: 5
        .then next

## Dependencies

    mkcmd = require '../../lib/mkcmd'
