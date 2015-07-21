
# HBase Master Install

TODO: [HBase backup node](http://willddy.github.io/2013/07/02/HBase-Add-Backup-Master-Node.html)

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs'
    module.exports.push 'ryba/hbase'
    module.exports.push require('./index').configure
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../../lib/hdp_service'
    module.exports.push require '../../lib/write_jaas'

## IPTables

| Service             | Port  | Proto | Info                   |
|---------------------|-------|-------|------------------------|
| HBase Master        | 60000 | http  | hbase.master.port      |
| HMaster Info Web UI | 60010 | http  | hbase.master.info.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'HBase Master # IPTables', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.master.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.master.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Info Web UI" }
        ]
        if: ctx.config.iptables.action is 'start'
      .then next

## Service

Install the "hbase-master" service, symlink the rc.d startup script inside
"/etc/init.d" and activate it on startup.

    module.exports.push name: 'HBase Master # Service', timeout: -1, handler: (ctx, next) ->
      ctx.hdp_service
        name: 'hbase-master'
        write: [
          match: /^\. \/etc\/default\/hbase .*$/m
          replace: '. /etc/default/hbase # RYBA FIX rc.d, DONT OVERWRITE'
          append: ". /lib/lsb/init-functions"
        ,
          # HDP default is "/etc/hbase/conf"
          match: /^CONF_DIR=.*$/m
          replace: "CONF_DIR=\"${HBASE_CONF_DIR}\" # RYBA HONORS /etc/default, DONT OVEWRITE"
        ,
          # HDP default is "/usr/lib/hbase/bin/hbase-daemon.sh"
          match: /^EXEC_PATH=.*$/m
          replace: "EXEC_PATH=\"${HBASE_HOME}/bin/hbase-daemon.sh\" # RYBA HONORS /etc/default, DONT OVEWRITE"
        ,
          # HDP default is "/var/run/hbase/hbase-hbase-master.pid"
          match: /^PIDFILE=.*$/m
          replace: "PIDFILE=\"${HBASE_PID_DIR}/hbase-hbase-master.pid\" # RYBA HONORS /etc/default, DONT OVEWRITE"
        ]
        etc_default:
          'hadoop': true
          'hbase':
            write: [
              match: /^export HBASE_HOME=.*$/m # HDP default is "/usr/lib/hbase"
              replace: "export HBASE_HOME=/usr/hdp/current/hbase-client # RYBA FIX"
            ]
      .then next

## Configure

*   [New Security Features in Apache HBase 0.98: An Operator's Guide][secop].

[secop]: http://fr.slideshare.net/HBaseCon/features-session-2

    module.exports.push name: 'HBase Master # Configure', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      mode = if ctx.has_module 'ryba/hbase/client' then 0o0644 else 0o0600
      ctx
      .hconfigure
        destination: "#{hbase.conf_dir}/hbase-site.xml"
        default: "#{__dirname}/../../resources/hbase/hbase-site.xml"
        local_default: true
        properties: hbase.site
        merge: true
        uid: hbase.user.name
        gid: hbase.group.name
        mode: mode # See slide 33 from [Operator's Guide][secop]
        backup: true
      .then next

# Opts

Environment passed to the Master before it starts.

    module.exports.push name: 'HBase Master # Opts', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      # return next() unless hbase.master_opts
      ctx.write
        destination: "#{hbase.conf_dir}/hbase-env.sh"
        match: /^export HBASE_MASTER_OPTS="(.*) \$\{HBASE_MASTER_OPTS\}" # RYBA .*/m
        replace: "export HBASE_MASTER_OPTS=\"#{hbase.master_opts} ${HBASE_MASTER_OPTS}\" # RYBA CONF \"ryba.hbase.master_opts\", DONT OVERWRITE"
        before: /^export HBASE_MASTER_OPTS=".*"$/m
        backup: true
      .then next

    module.exports.push 'ryba/hadoop/hdfs_nn/wait'

    module.exports.push name: 'HBase Master # HDFS layout', timeout: -1, handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.waitForExecution mkcmd.hdfs(ctx, "hdfs dfs -test -d /apps"), (err) -> # , code_skipped: 1
        return next err if err
        dirs = hbase.site['hbase.bulkload.staging.dir'].split '/'
        return next err "Invalid property \"hbase.bulkload.staging.dir\"" unless dirs.length > 2 and path.join('/', dirs[0], '/', dirs[1]) is '/apps'
        for dir, index in dirs.slice 2
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
        ctx.then next

## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master,
RegionServer, and HBase client host machines.

Environment file is enriched by "ryba/hbase" # HBase # Env".

    module.exports.push name: 'HBase Master # Zookeeper JAAS', timeout: -1, handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.write_jaas
        destination: "#{hbase.conf_dir}/hbase-master.jaas"
        content: Client:
          principal: hbase.site['hbase.master.kerberos.principal'].replace '_HOST', ctx.config.host
          keyTab: hbase.site['hbase.master.keytab.file']
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o700
      .then next

## Kerberos

https://blogs.apache.org/hbase/entry/hbase_cell_security
https://hbase.apache.org/book/security.html

    module.exports.push name: 'HBase Master # Kerberos', handler: (ctx, next) ->
      {hadoop_group, hbase, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: hbase.site['hbase.master.kerberos.principal'].replace '_HOST', ctx.config.host
        randkey: true
        keytab: hbase.site['hbase.master.keytab.file']
        uid: hbase.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      .then next

    module.exports.push name: 'HBase Master # Kerberos Admin', handler: (ctx, next) ->
      {hbase, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: hbase.admin.principal
        password: hbase.admin.password
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      .then next

## Metrics

Enable stats collection in Ganglia and Graphite

    module.exports.push name: 'HBase Master # Metrics', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx
      .write
        destination: "#{hbase.conf_dir}/hadoop-metrics2-hbase.properties"
        write: for k, v of hbase.metrics
          match: ///^#{quote k}=.*$///mg
          replace: if v is null then "" else "#{k}=#{v}"
          append: v isnt null
        backup: true
      .then next

## SPNEGO

Ensure we have read access to the spnego keytab soring the server HTTP
principal.

    module.exports.push name: 'HBase RegionServer # SPNEGO', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.execute
        cmd: "su -l #{hbase.user.name} -c 'test -r /etc/security/keytabs/spnego.service.keytab'"
      .then next

# Module dependencies

    path = require 'path'
    mkcmd = require '../../lib/mkcmd'
    quote = require 'regexp-quote'
