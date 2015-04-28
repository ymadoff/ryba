
# Hive Server2 Install

TODO: Implement lock for Hive Server2
http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Installation-Guide/cdh4ig_topic_18_5.html

Resources:
*   [Cloudera security instruction for CDH5](http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_sg_hiveserver2_security.html)

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/krb5_client'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/mapred_client'
    module.exports.push 'ryba/tez'
    module.exports.push 'ryba/hive/client/install' # Install the Hive and HCatalog service
    module.exports.push 'ryba/hbase/client'
    module.exports.push 'ryba/hive/hcatalog/wait'
    module.exports.push require('./index').configure
    module.exports.push require '../../lib/hdp_service'

## IPTables

| Service        | Port  | Proto | Parameter            |
|----------------|-------|-------|----------------------|
| Hive Server    | 10001 | tcp   | env[HIVE_PORT]       |


IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'Hive Server2 # IPTables', handler: (ctx, next) ->
      {hive} = ctx.config.ryba
      hive_server_port = if hive.site['hive.server2.transport.mode'] is 'binary'
      then hive.site['hive.server2.thrift.port']
      else hive.site['hive.server2.thrift.http.port']
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hive_server_port, protocol: 'tcp', state: 'NEW', comment: "Hive Server" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Startup

Install the "hive-server2" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

The server is not activated on startup because they endup as zombies if HDFS
isnt yet started.

    module.exports.push name: 'Hive Server2 # Startup', handler: (ctx, next) ->
      {hive} = ctx.config.ryba
      ctx.hdp_service
        name: 'hive-server2'
        startup: false
        write: [
          match: /^\. \/etc\/default\/hive-server2 .*$/m
          replace: '. /etc/default/hive-server2 # RYBA FIX rc.d, DONT OVERWRITE'
          append: ". /lib/lsb/init-functions"
        ,
          # HDP default is "/usr/lib/hive/bin/hive"
          match: /^EXEC_PATH=.*$/m
          replace: "EXEC_PATH=\"/usr/hdp/current/hive-server2/bin/hive\" # RYBA FIX, DONT OVEWRITE"
        ,
          # HDP default is "LOG_FILE=/var/log/hive/${DAEMON}.out"
          match: /^(\s+)LOG_FILE=.*$/m
          replace: "$1LOG_FILE=\"#{hive.server2.log_dir}/${DAEMON}.out\" # RYBA FIX, DONT OVEWRITE"
        ,
          # HDP default is "/var/run/hive/hive-server2.pid"
          match: /^PIDFILE=.*$/m
          replace: "PIDFILE=\"#{hive.server2.pid_dir}/hcat.pid\" # RYBA FIX, DONT OVEWRITE"
        ]
        etc_default: true
      , next

    module.exports.push name: 'Hive Server2 # Configure', handler: (ctx, next) ->
      {hive} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hive.conf_dir}/hive-site.xml"
        default: "#{__dirname}/../../resources/hive/hive-site.xml"
        local_default: true
        properties: hive.site
        merge: true
        backup: true
      , next

## Env

Enrich the "hive-env.sh" file with the value of the configuration property
"ryba.hive.server2.opts". Internally, the environmental variable
"HADOOP_CLIENT_OPTS" is enriched and only apply to the Hive Server2.

Using this functionnality, a user may for example raise the heap size of Hive
Server2 to 4Gb by setting a value equal to "-Xmx4096m".

    module.exports.push name: 'Hive Server2 # Env', handler: (ctx, next) ->
      {hive} = ctx.config.ryba
      ctx.write
        destination: "#{hive.conf_dir}/hive-env.sh"
        replace: """
        if [ "$SERVICE" = "hiveserver2" ]; then
          # export HADOOP_CLIENT_OPTS="-Dcom.sun.management.jmxremote -Djava.rmi.server.hostname=130.98.196.54 -Dcom.sun.management.jmxremote.rmi.port=9526 -Dcom.sun.management.jmxremote.port=9526 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false  $HADOOP_CLIENT_OPTS"
          export HADOOP_HEAPSIZE="#{hive.server2.heapsize}"
          export HADOOP_CLIENT_OPTS="-Xmx${HADOOP_HEAPSIZE}m #{hive.server2.opts} ${HADOOP_CLIENT_OPTS}"
        fi
        """
        from: '# RYBA HIVE SERVER2 START'
        to: '# RYBA HIVE SERVER2 END'
        append: true
        eof: true
        backup: true
      , next

## Layout

Create the directories to store the logs and pid information. The properties
"ryba.hive.server2.log\_dir" and "ryba.hive.server2.pid\_dir" may be modified.

    module.exports.push name: 'Hive Server2 # Layout', timeout: -1, handler: (ctx, next) ->
      {hive} = ctx.config.ryba
      # Required by service "hive-hcatalog-server"
      ctx.mkdir [
        destination: hive.server2.log_dir
        uid: hive.user.name
        gid: hive.group.name
        parent: true
      ,
        destination: hive.server2.pid_dir
        uid: hive.user.name
        gid: hive.group.name
        parent: true
      ], next

    module.exports.push name: 'Hive Server2 # Kerberos', handler: (ctx, next) ->
      {hive, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: hive.site['hive.server2.authentication.kerberos.principal'].replace '_HOST', ctx.config.host
        randkey: true
        keytab: hive.site['hive.server2.authentication.kerberos.keytab']
        uid: hive.user.name
        gid: hive.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
        not_if: hive.site['hive.metastore.kerberos.principal'] is hive.site['hive.server2.authentication.kerberos.principal']
      , next

    module.exports.push name: 'Hive Server2 # Logs', handler: (ctx, next) ->
      ctx.write [
        source: "#{__dirname}/../../resources/hive/hive-exec-log4j.properties.template"
        local_source: true
        destination: '/etc/hive/conf/hive-exec-log4j.properties'
      ,
        source: "#{__dirname}/../../resources/hive/hive-log4j.properties.template"
        local_source: true
        destination: '/etc/hive/conf/hive-log4j.properties'
      ], next

