
# HBase RegionServer Install

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs'
    module.exports.push 'ryba/hbase'
    module.exports.push require('./index').configure
    module.exports.push require '../../lib/hdp_service'
    module.exports.push require '../../lib/write_jaas'

## IPTables

| Service                      | Port  | Proto | Info                         |
|------------------------------|-------|-------|------------------------------|
| HBase Region Server          | 60020 | http  | hbase.regionserver.port      |
| HMaster Region Server Web UI | 60030 | http  | hbase.regionserver.info.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'HBase RegionServer # IPTables', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.regionserver.port'], protocol: 'tcp', state: 'NEW', comment: "HBase RegionServer" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.regionserver.info.port'], protocol: 'tcp', state: 'NEW', comment: "HBase RegionServer Info Web UI" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Service

Install the "hbase-regionserver" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

    module.exports.push name: 'HBase RegionServer # Service', timeout: -1, handler: (ctx, next) ->
      ctx.hdp_service
        name: 'hbase-regionserver'
        write: [
          replace: 'RETVAL=0'
          before: /^case ".*?" in$/m
        ,
          match: /^exit (\d|\\$RETVAL)$/m
          replace: 'exit $RETVAL'
        ,
          replace: '        RETVAL=$?'
          append: '        status'
        ]
        etc_default:
          'hadoop': true
          'hbase':
            write: [
              match: /^export HBASE_HOME=.*$/m # HDP default is "/var/lib/hive-hcatalog"
              replace: "export HBASE_HOME=/usr/hdp/current/hbase-client # RYBA FIX"
            ]
      , next

## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master,
RegionServer, and HBase client host machines.

    module.exports.push name: 'HBase RegionServer # Zookeeper JAAS', timeout: -1, handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.write_jaas
        destination: "#{hbase.conf_dir}/hbase-regionserver.jaas"
        content: Client:
          principal: hbase.site['hbase.regionserver.kerberos.principal'].replace '_HOST', ctx.config.host
          keyTab: hbase.site['hbase.regionserver.keytab.file']
        uid: hbase.user.name
        gid: hbase.group.name
      , next

    module.exports.push name: 'HBase RegionServer # Kerberos', timeout: -1, handler: (ctx, next) ->
      {hadoop_group, hbase, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      if ctx.has_module 'ryba/hbase/master'
        if hbase.site['hbase.master.kerberos.principal'] isnt hbase.site['hbase.regionserver.kerberos.principal']
          return next Error "HBase principals must match in single node"
        require('./master').configure(ctx)
        ctx.copy
          source: hbase.site['hbase.master.keytab.file']
          destination: hbase.site['hbase.regionserver.keytab.file']
        , next
      else
        ctx.krb5_addprinc
          principal: hbase.site['hbase.regionserver.kerberos.principal'].replace '_HOST', ctx.config.host
          randkey: true
          keytab: hbase.site['hbase.regionserver.keytab.file']
          uid: hbase.user.name
          gid: hadoop_group.name
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: admin_server
        , next

## Configure

*   [New Security Features in Apache HBase 0.98: An Operator's Guide][secop].

[secop]: http://fr.slideshare.net/HBaseCon/features-session-2

    module.exports.push name: 'HBase RegionServer # Configure', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      mode = if ctx.has_module 'ryba/hbase/client' then 0o0644 else 0o0600
      ctx.hconfigure
        destination: "#{hbase.conf_dir}/hbase-site.xml"
        default: "#{__dirname}/../../resources/hbase/hbase-site.xml"
        local_default: true
        properties: hbase.site
        merge: true
        uid: hbase.user.name
        gid: hbase.group.name
        mode: mode # See slide 33 from [Operator's Guide][secop]
        backup: true
      , next

## Opts

Environment passed to the RegionServer before it starts.

    module.exports.push name: 'HBase RegionServer # Opts', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      return next() unless hbase.regionserver_opts
      ctx.write
        destination: "#{hbase.conf_dir}/hbase-env.sh"
        match: /^export HBASE_REGIONSERVER_OPTS="(.*) \$\{HBASE_REGIONSERVER_OPTS\}" # GENERATED BY RYBA, DONT OVEWRITE/mg
        replace: "export HBASE_REGIONSERVER_OPTS=\"${HBASE_REGIONSERVER_OPTS} #{hbase.regionserver_opts}\" # GENERATED BY RYBA, DONT OVEWRITE"
        append: /^export HBASE_REGIONSERVER_OPTS=".*"$/mg
        backup: true
      , next

## Metrics

Enable stats collection in Ganglia.

    module.exports.push name: 'HBase RegionServer # Metrics', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      collector = ctx.host_with_module 'ryba/hadoop/ganglia_collector'
      return next() unless collector
      ctx.upload
        source: "#{__dirname}/../../resources/hbase/hadoop-metrics.properties.regionservers-GANGLIA"
        destination: "#{hbase.conf_dir}/hadoop-metrics.properties"
        match: 'TODO-GANGLIA-SERVER'
        replace: collector
      , next

## SPNEGO

Ensure we have read access to the spnego keytab soring the server HTTP
principal.

    module.exports.push name: 'HBase RegionServer # SPNEGO', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.execute
        cmd: "su -l #{hbase.user.name} -c 'test -r /etc/security/keytabs/spnego.service.keytab'"
      , next

## Start

Execute the "ryba/hbase/regionserver/start" module to start the RegionServer.

    module.exports.push 'ryba/hbase/regionserver/start'

## Check

Check this installation.

    module.exports.push 'ryba/hbase/regionserver/check'
