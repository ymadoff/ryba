# Hadoop HDFS JournalNode Install

It apply to a secured HDFS installation with Kerberos.

The JournalNode daemon is relatively lightweight, so these daemons may reasonably
be collocated on machines with other Hadoop daemons, for example NameNodes, the
JobTracker, or the YARN ResourceManager.

There must be at least 3 JournalNode daemons, since edit log modifications must
be written to a majority of JNs. To increase the number of failures a system
can tolerate, deploy an odd number of JNs because the system can tolerate at
most (N - 1) / 2 failures to continue to function normally.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs'
    module.exports.push require('./index').configure
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../../lib/hdp_service'

## IPTables

| Service     | Port | Proto  | Parameter                                      |
|-------------|------|--------|------------------------------------------------|
| journalnode | 8485 | tcp    | hdp.hdfs.site['dfs.journalnode.rpc-address']   |
| journalnode | 8480 | tcp    | hdp.hdfs.site['dfs.journalnode.http-address']  |
| journalnode | 8481 | tcp    | hdp.hdfs.site['dfs.journalnode.https-address'] |

Note, "dfs.journalnode.rpc-address" is used by "dfs.namenode.shared.edits.dir".

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'HDFS JN # IPTables', handler: (ctx, next) ->
      {hdfs} = ctx.config.ryba
      rpc = hdfs.site['dfs.journalnode.rpc-address'].split(':')[1]
      http = hdfs.site['dfs.journalnode.http-address'].split(':')[1]
      https = hdfs.site['dfs.journalnode.https-address'].split(':')[1]
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: rpc, protocol: 'tcp', state: 'NEW', comment: "HDFS JournalNode" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: http, protocol: 'tcp', state: 'NEW', comment: "HDFS JournalNode" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: https, protocol: 'tcp', state: 'NEW', comment: "HDFS JournalNode" }
        ]
        if: ctx.config.iptables.action is 'start'
      .then next

## Layout

The JournalNode data are stored inside the directory defined by the
"dfs.journalnode.edits.dir" property.

    module.exports.push name: 'HDFS JN # Layout', handler: (ctx, next) ->
      {hdfs, hadoop_conf_dir} = ctx.config.ryba
      ctx.mkdir
        destination: hdfs.site['dfs.journalnode.edits.dir'].split ','
        uid: 'hdfs'
        gid: 'hadoop'
      .then next

## Service

Install the "hadoop-hdfs-journalnode" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

    module.exports.push name: 'HDFS JN # Service', handler: (ctx, next) ->
      {hdfs} = ctx.config.ryba
      ctx.hdp_service
        name: 'hadoop-hdfs-journalnode'
        write: [
          match: /^\. \/etc\/default\/hadoop-hdfs-journalnode .*$/m
          replace: '. /etc/default/hadoop-hdfs-journalnode # RYBA FIX rc.d, DONT OVERWRITE'
          append: ". /lib/lsb/init-functions"
        ,
          # HDP default is "/usr/lib/hadoop/sbin/hadoop-daemon.sh"
          match: /^EXEC_PATH=.*$/m
          replace: "EXEC_PATH=\"${HADOOP_HOME}/sbin/hadoop-daemon.sh\" # RYBA HONORS /etc/default, DONT OVEWRITE"
        ,
          # HDP default is "/var/run/hadoop-hdfs/hadoop-hdfs-journalnode.pid"
          match: /^PIDFILE=".*".*$/mg
          replace: "PIDFILE=\"${HADOOP_PID_DIR}/hadoop-$HADOOP_IDENT_STRING-journalnode.pid\" # RYBA FIX, DONT OVEWRITE"
        ]
        etc_default:
          'hadoop-hdfs-journalnode':
            write: [
              match: /^export HADOOP_PID_DIR=.*$/m # HDP default is "/var/run/hadoop-hdfs"
              replace: "export HADOOP_PID_DIR=#{hdfs.pid_dir} # RYBA"
            ,
              match: /^export HADOOP_LOG_DIR=.*$/m # HDP default is "/var/log/hadoop-hdfs"
              replace: "export HADOOP_LOG_DIR=#{hdfs.log_dir} # RYBA"
            ,
              match: /^export HADOOP_IDENT_STRING=.*$/m # HDP default is "hdfs"
              replace: "export HADOOP_IDENT_STRING=#{hdfs.user.name} # RYBA"
            ]
      .then next

    # module.exports.push name: 'HDFS JN # Startup', handler: (ctx, next) ->
    #   {hdfs} = ctx.config.ryba
    #   modified = false
    #   do_install = ->
    #     ctx.service
    #       name: 'hadoop-hdfs-journalnode'
    #       startup: true
    #     , (err, serviced) ->
    #       return next err if err
    #       modified = true if serviced
    #       do_fix()
    #   do_fix = ->
    #     ctx.write
    #       destination: '/etc/init.d/hadoop-hdfs-journalnode'
    #       write: [
    #         match: /^PIDFILE=".*"$/m
    #         replace: "PIDFILE=\"#{hdfs.pid_dir}/$SVC_USER/hadoop-hdfs-journalnode.pid\""
    #       ,
    #         match: /^(\s+start_daemon)\s+(\$EXEC_PATH.*)$/m
    #         replace: "$1 -u $SVC_USER $2"
    #       ]
    #     , (err, written) ->
    #       return next err if err
    #       modified = true if written
    #       do_end()
    #   do_end = ->
    #     next null, modified
    #   do_install()

## Configure

Update the "hdfs-site.xml" file with the "dfs.journalnode.edits.dir" property.

Register the SPNEGO service principal in the form of "HTTP/{host}@{realm}" into
the "hdfs-site.xml" file. The impacted properties are
"dfs.journalnode.kerberos.internal.spnego.principal",
"dfs.journalnode.kerberos.principal" and "dfs.journalnode.keytab.file". The
SPNEGO tocken is stored inside the "/etc/security/keytabs/spnego.service.keytab"
keytab, also used by the NameNodes, DataNodes, ResourceManagers and
NodeManagers.

    module.exports.push name: 'HDFS JN # Configure', handler: (ctx, next) ->
      {hdfs, hadoop_conf_dir, hadoop_group} = ctx.config.ryba
      ctx
      .hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        default: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
        local_default: true
        properties: hdfs.site
        uid: hdfs.user.name
        gid: hadoop_group.name
        merge: true
        backup: true
      .then next

## Dependencies

    lifecycle = require '../../lib/lifecycle'
    mkcmd = require '../../lib/mkcmd'
