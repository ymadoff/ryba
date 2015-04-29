
# Hadoop HDFS SecondaryNameNode Install

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/hdfs'
    module.exports.push require('./index').configure
    module.exports.push require '../../lib/hdp_service'

## IPTables

| Service    | Port | Proto  | Parameter                  |
|------------|------|--------|----------------------------|
| namenode  | 50070 | tcp    | dfs.namdnode.http-address  |
| namenode  | 50470 | tcp    | dfs.namenode.https-address |
| namenode  | 8020  | tcp    | fs.defaultFS               |
| namenode  | 8019  | tcp    | dfs.ha.zkfc.port           |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'HDFS SNN # IPTables', handler: (ctx, next) ->
      {hdfs} = ctx.config.ryba
      [_, http_port] = hdfs.site['dfs.namenode.secondary.http-address'].split ':'
      [_, https_port] = hdfs.site['dfs.namenode.secondary.https-address'].split ':'
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: http_port, protocol: 'tcp', state: 'NEW', comment: "HDFS SNN HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: https_port, protocol: 'tcp', state: 'NEW', comment: "HDFS SNN HTTPS" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Service

Install the "hadoop-hdfs-secondarynamenode" service, symlink the rc.d startup
script inside "/etc/init.d" and activate it on startup.

    module.exports.push name: 'HDFS SNN # Service', handler: (ctx, next) ->
      ctx.hdp_service 'hadoop-hdfs-secondarynamenode', next

    # module.exports.push name: 'HDFS SNN # Service', timeout: -1, handler: (ctx, next) ->
    #   {hdfs} = ctx.config.ryba
    #   ctx.service
    #     name: 'hadoop-hdfs-secondarynamenode'
    #     startup: true
    #   , (err, serviced) ->
    #     return next err if err
    #     ctx.write
    #       destination: '/etc/init.d/hadoop-hdfs-secondarynamenode'
    #       write: [
    #         {match: /^PIDFILE=".*"$/m, replace: "PIDFILE=\"#{hdfs.pid_dir}/$SVC_USER/hadoop-hdfs-secondarynamenode.pid\""}
    #         {match: /^(\s+start_daemon)\s+(\$EXEC_PATH.*)$/m, replace: "$1 -u $SVC_USER $2"}]
    #     , (err, written) ->
    #       next err, serviced or written

    module.exports.push name: 'HDFS SNN # Directories', timeout: -1, handler: (ctx, next) ->
      {hdfs, hadoop_group} = ctx.config.ryba
      ctx.log "Create SNN data, checkpind and pid directories"
      pid_dir = hdfs.pid_dir.replace '$USER', hdfs.user.name
      ctx.mkdir [
        destination: hdfs.site['dfs.namenode.checkpoint.dir'].split ','
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
      ,
        destination: "#{pid_dir}"
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
      ], next

    module.exports.push name: 'HDFS SNN # Kerberos', handler: (ctx, next) ->
      {realm, hdfs} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: "nn/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: hdfs.site['dfs.secondary.namenode.keytab.file']
        uid: 'hdfs'
        gid: 'hadoop'
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next

# Configure

    module.exports.push name: 'HDFS SNN # Configure', handler: (ctx, next) ->
      {hdfs, hadoop_conf_dir, hadoop_group} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
        local_default: true
        properties: hdfs.site
        uid: hdfs.user
        gid: hadoop_group
        merge: true
        backup: true
      , next
