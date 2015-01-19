
# HBase RegionServer Install

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/hdfs'
    module.exports.push 'ryba/hbase/_'
    module.exports.push require('./regionserver').configure

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
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.regionserver.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.regionserver.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Info Web UI" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Service

Install and configure the startup script in 
"/etc/init.d/hbase-regionserver".

    module.exports.push name: 'HBase RegionServer # Startup', timeout: -1, handler: (ctx, next) ->
      modified = false
      do_install = ->
        ctx.service 
          name: 'hbase-regionserver'
        , (err, serviced) ->
          return next err if err
          modified = true if serviced
          do_write()
      do_write = ->
        ctx.write
          destination: '/etc/init.d/hbase-regionserver'
          match: /^\s+exit 3 # Ryba: Fix invalid exit code*$/m
          replace: '            exit 3 # Ryba: Fix invalid exit code'
          append: /^\s+echo "not running."$/m
        , (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        next null, modified
      do_install()

## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master, 
RegionServer, and HBase client host machines.

    module.exports.push name: 'HBase RegionServer # Zookeeper JAAS', timeout: -1, handler: (ctx, next) ->
      {jaas_server, hbase} = ctx.config.ryba
      ctx.write
        destination: "#{hbase.conf_dir}/hbase-regionserver.jaas"
        content: jaas_server
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o700
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

## SPNEGO

Check if keytab file exists and if read permission is granted to the HBase user.

Note: The Namenode webapp located in "/usr/lib/hbase/hbase-webapps/regionserver" is
using the hadoop conf directory to retrieve the SPNEGO keytab. The user "hbase"
is added membership to the group hadoop to gain read access.

    module.exports.push name: 'HBase RegionServer # FIX SPNEGO', handler: (ctx, next) ->
      {hbase, hadoop_group} = ctx.config.ryba
      {hdfs} = ctx.config.ryba
      ctx.execute
        cmd: """
          if groups #{hbase.user.name} | grep #{hadoop_group.name}; then exit 2; fi
          usermod -G #{hadoop_group.name} #{hbase.user.name}
        """
        code_skipped: 2
      , (err, modified) ->
        return next err if err
        ctx.execute
          cmd: "su -l #{hbase.user.name} -c 'test -r /etc/security/keytabs/spnego.service.keytab'"
        , (err) ->
          next err, modified
      # ctx.copy [
      #   source: '/etc/security/keytabs/spnego.service.keytab'
      #   destination: hbase.site['hbase.thrift.keytab.file']
      #   uid: hbase.user.name
      #   gid: hbase.group.name
      #   mode: 0o660
      # ,
      #   source: '/etc/security/keytabs/spnego.service.keytab'
      #   destination: hbase.site['hbase.rest.authentication.kerberos.keytab']
      #   uid: hbase.user.name
      #   gid: hbase.group.name
      #   mode: 0o660
      
      # ], (err, copied) ->
      #   return next err, copied

## Metrics

Enable stats collection in Ganglia.

    module.exports.push name: 'HBase RegionServer # Metrics', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      collector = ctx.host_with_module 'ryba/hadoop/ganglia_collector'
      return next() unless collector
      ctx.upload
        source: "#{__dirname}/../resources/hbase/hadoop-metrics.properties.regionservers-GANGLIA"
        destination: "#{hbase.conf_dir}/hadoop-metrics.properties"
        match: 'TODO-GANGLIA-SERVER'
        replace: collector
      , next

## Start

Execute the "ryba/hbase/regionserver_start" module to start the RegionServer.

    module.exports.push 'ryba/hbase/regionserver_start'

## Check

Check this installation.

    module.exports.push 'ryba/hbase/regionserver_check'
