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
    module.exports.push require('./hdfs_jn').configure

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
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

## Layout

The JournalNode data are stored inside the directory defined by the 
"dfs.journalnode.edits.dir" property.

    module.exports.push name: 'HDFS JN # Layout', handler: (ctx, next) ->
      {hdfs, hadoop_conf_dir} = ctx.config.ryba
      ctx.mkdir
        destination: hdfs.site['dfs.journalnode.edits.dir'].split ','
        uid: 'hdfs'
        gid: 'hadoop'
      , next

## Startup

Install and configure the startup script in 
"/etc/init.d/hadoop-hdfs-journalnode".

    module.exports.push name: 'HDFS JN # Startup', handler: (ctx, next) ->
      {hdfs} = ctx.config.ryba
      modified = false
      do_install = ->
        ctx.service
          name: 'hadoop-hdfs-journalnode'
          startup: true
        , (err, serviced) ->
          return next err if err
          modified = true if serviced
          do_fix()
      do_fix = ->
        ctx.write
          destination: '/etc/init.d/hadoop-hdfs-journalnode'
          write: [
            match: /^PIDFILE=".*"$/m
            replace: "PIDFILE=\"#{hdfs.pid_dir}/$SVC_USER/hadoop-hdfs-journalnode.pid\""
          ,
            match: /^(\s+start_daemon)\s+(\$EXEC_PATH.*)$/m
            replace: "$1 -u $SVC_USER $2"
          ]
        , (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        next null, modified
      do_install()

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
      {hdfs, hadoop_conf_dir} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        properties: hdfs.site
        merge: true
        backup: true
      , next

## Configure HA

Add High Availability specific properties to the "hdfs-site.xml" file. Those
properties include "dfs.namenode.shared.edits.dir". Note, this might not be
read on JN side (see [DFSConfigKeys.java][keys]).

    module.exports.push name: 'HDFS JN # Configure HA', handler: (ctx, next) ->
      {hadoop_conf_dir, ha_client_config} = ctx.config.ryba
      journalnodes = ctx.hosts_with_module 'ryba/hadoop/hdfs_jn'
      ha_client_config['dfs.namenode.shared.edits.dir'] = (for jn in journalnodes then "#{jn}:8485").join ';'
      ha_client_config['dfs.namenode.shared.edits.dir'] = "qjournal://#{ha_client_config['dfs.namenode.shared.edits.dir']}/#{ha_client_config['dfs.nameservices']}"
      ctx.hconfigure
        destination: "#{hadoop_conf_dir}/hdfs-site.xml"
        properties: ha_client_config
        merge: true
        backup: true
      , next

## Module Dependencies

    lifecycle = require '../lib/lifecycle'
    mkcmd = require '../lib/mkcmd'

[keys]: https://github.com/apache/hadoop-common/blob/trunk/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/DFSConfigKeys.java



