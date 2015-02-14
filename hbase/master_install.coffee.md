
# HBase Master Install

TODO: [HBase backup node](http://willddy.github.io/2013/07/02/HBase-Add-Backup-Master-Node.html)

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs'
    module.exports.push 'ryba/hbase/_'
    module.exports.push require('./master').configure

## IPTables

| Service             | Port  | Proto | Info                   |
|---------------------|-------|-------|------------------------|
| HBase Master        | 60000 | http  | hbase.master.port      |
| HMaster Info Web UI | 60010 | http  | hbase.master.info.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'HBase master # IPTables', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.master.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.master.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Info Web UI" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Service

Install and configure the startup script in 
"/etc/init.d/hbase-master".

    module.exports.push name: 'HBase Master # Service', timeout: -1, handler: (ctx, next) ->
      ctx.service
        name: 'hbase-master'
      , next

## Configure

*   [New Security Features in Apache HBase 0.98: An Operator's Guide][secop].

[secop]: http://fr.slideshare.net/HBaseCon/features-session-2

    module.exports.push name: 'HBase Master # Configure', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      mode = if ctx.has_module 'ryba/hbase/client' then 0o0644 else 0o0600
      ctx.hconfigure
        destination: "#{hbase.conf_dir}/hbase-site.xml"
        default: "#{__dirname}/../resources/hbase/hbase-site.xml"
        local_default: true
        properties: hbase.site
        merge: true
        uid: hbase.user.name
        gid: hbase.group.name
        mode: mode # See slide 33 from [Operator's Guide][secop]
        backup: true
      , next

    module.exports.push name: 'HBase Master # HDFS layout', timeout: -1, handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.waitForExecution mkcmd.hdfs(ctx, "hdfs dfs -test -d /apps"), code_skipped: 1, (err) ->
        return next err if err
        dirs = hbase.site['hbase.bulkload.staging.dir'].split '/'
        return next err "Invalid property \"hbase.bulkload.staging.dir\"" unless dirs.length > 2 and path.join('/', dirs[0], '/', dirs[1]) is '/apps'
        ctx.log "Create /apps/hbase"
        modified = false
        each(dirs.slice 2)
        .on 'item', (dir, index, next) ->
          dir = dirs.slice(0, 3 + index).join '/'
          cmd = """
          if hdfs dfs -ls #{dir} &>/dev/null; then exit 2; fi
          hdfs dfs -mkdir #{dir}
          hdfs dfs -chown #{hbase.user.name} #{dir}
          """
          cmd += "\nhdfs dfs -chmod 711 #{dir}"  if 3 + index is dirs.length
          ctx.execute
            cmd: mkcmd.hdfs ctx, cmd
            code_skipped: 2
          , (err, executed, stdout) ->
            modified = true if executed
            next err
        .on 'both', (err) ->
          next err, modified

## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master, 
RegionServer, and HBase client host machines.

Environment file is enriched by "ryba/hbase/_ # HBase # Env".

    module.exports.push name: 'HBase master # Zookeeper JAAS', timeout: -1, handler: (ctx, next) ->
      {jaas_server, hbase} = ctx.config.ryba
      ctx.write
        destination: "#{hbase.conf_dir}/hbase-master.jaas"
        content: jaas_server
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o700
      , next

https://blogs.apache.org/hbase/entry/hbase_cell_security
https://hbase.apache.org/book/security.html

    module.exports.push name: 'HBase Master # Kerberos', handler: (ctx, next) ->
      {hadoop_group, hbase, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc [
        principal: hbase.site['hbase.master.kerberos.principal'].replace '_HOST', ctx.config.host
        randkey: true
        keytab: hbase.site['hbase.master.keytab.file']
        uid: hbase.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      ], next

## Metrics

Enable stats collection in Ganglia.

    module.exports.push name: 'HBase Master # Metrics', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      collector = ctx.host_with_module 'ryba/hadoop/ganglia_collector'
      return next() unless collector
      ctx.upload
        source: "#{__dirname}/../resources/hbase/hadoop-metrics.properties.master-GANGLIA"
        destination: "#{hbase.conf_dir}/hadoop-metrics.properties"
        match: 'TODO-GANGLIA-SERVER'
        replace: collector
      , next

    module.exports.push name: 'HBase Master # Kerberos Admin', handler: (ctx, next) ->
      {hbase, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: hbase.admin.principal
        password: hbase.admin.password
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next

## SPNEGO

Ensure we have read access to the spnego keytab soring the server HTTP
principal.

    module.exports.push name: 'HBase RegionServer # SPNEGO', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.execute
        cmd: "su -l #{hbase.user.name} -c 'test -r /etc/security/keytabs/spnego.service.keytab'"
      , next

    module.exports.push 'ryba/hbase/master_start'

## Check

    module.exports.push 'ryba/hbase/master_check'

# Module dependencies

    each = require 'each'
    path = require 'path'
    mkcmd = require '../lib/mkcmd'

