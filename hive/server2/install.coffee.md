
# Hive Server2 Install

TODO: Implement lock for Hive Server2
http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Installation-Guide/cdh4ig_topic_18_5.html

HDP 2.1 and 2.2 dont support secured Hive metastore in HA mode, see
[HIVE-9622](https://issues.apache.org/jira/browse/HIVE-9622).

Resources:
*   [Cloudera security instruction for CDH5](http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_sg_hiveserver2_security.html)

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'masson/core/krb5_client'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'ryba/hadoop/core_ssl'
    module.exports.push 'ryba/hadoop/mapred_client/install'
    module.exports.push 'ryba/tez/install'
    module.exports.push 'ryba/hive/client/install' # Install the Hive and HCatalog service
    module.exports.push 'ryba/hbase/client/install'
    module.exports.push 'ryba/hive/hcatalog/wait'
    module.exports.push 'ryba/lib/hconfigure'
    module.exports.push 'ryba/lib/hdp_select'
    # module.exports.push require('./index').configure

## IPTables

| Service        | Port  | Proto | Parameter            |
|----------------|-------|-------|----------------------|
| Hive Server    | 10001 | tcp   | env[HIVE_PORT]       |


IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push header: 'Hive Server2 # IPTables', handler: ->
      {hive} = @config.ryba
      hive_server_port = if hive.site['hive.server2.transport.mode'] is 'binary'
      then hive.site['hive.server2.thrift.port']
      else hive.site['hive.server2.thrift.http.port']
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hive_server_port, protocol: 'tcp', state: 'NEW', comment: "Hive Server" }
        ]
        if: @config.iptables.action is 'start'

## Startup

Install the "hive-server2" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

The server is not activated on startup because they endup as zombies if HDFS
isnt yet started.

    module.exports.push header: 'Hive Server2 # Startup', handler: ->
      @service
        name: 'hive-server2'
      @hdp_select
        name: 'hive-server2'
      @write
        source: "#{__dirname}/../resources/hive-server2"
        local_source: true
        destination: '/etc/init.d/hive-server2'
        mode: 0o0755
        unlink: true
      @execute
        cmd: "service hive-server2 restart"
        if: -> @status -3

    module.exports.push header: 'Hive Server2 # Configure', handler: ->
      {hive} = @config.ryba
      @hconfigure
        destination: "#{hive.server2.conf_dir}/hive-site.xml"
        default: "#{__dirname}/../../resources/hive/hive-site.xml"
        local_default: true
        properties: hive.site
        merge: true
        backup: true

## Env

Enrich the "hive-env.sh" file with the value of the configuration property
"ryba.hive.server2.opts". Internally, the environmental variable
"HADOOP_CLIENT_OPTS" is enriched and only apply to the Hive Server2.

Using this functionnality, a user may for example raise the heap size of Hive
Server2 to 4Gb by setting a value equal to "-Xmx4096m".

    module.exports.push header: 'Hive Server2 # Env', handler: ->
      {hive} = @config.ryba
      @write
        destination: "#{hive.server2.conf_dir}/hive-env.sh"
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

## Layout

Create the directories to store the logs and pid information. The properties
"ryba.hive.server2.log\_dir" and "ryba.hive.server2.pid\_dir" may be modified.

    module.exports.push header: 'Hive Server2 # Layout', timeout: -1, handler: ->
      {hive} = @config.ryba
      # Required by service "hive-hcatalog-server"
      @mkdir
        destination: hive.server2.log_dir
        uid: hive.user.name
        gid: hive.group.name
        parent: true
      @mkdir
        destination: hive.server2.pid_dir
        uid: hive.user.name
        gid: hive.group.name
        parent: true

## SSL

    module.exports.push
      header: 'Hive Client # SSL'
      if: -> @config.ryba.hive.site['hive.server2.use.SSL'] is 'true'
      handler: ->
        {ssl, ssl_server, ssl_client, hadoop_conf_dir} = @config.ryba
        tmp_location = "/var/tmp/ryba/ssl"
        {hive} = @config.ryba
        @upload
          source: ssl.cacert
          destination: "#{tmp_location}/#{path.basename ssl.cacert}"
          mode: 0o0600
          shy: true
        @upload
          source: ssl.cert
          destination: "#{tmp_location}/#{path.basename ssl.cert}"
          mode: 0o0600
          shy: true
        @upload
          source: ssl.key
          destination: "#{tmp_location}/#{path.basename ssl.key}"
          mode: 0o0600
          shy: true
        @java_keystore_add
          keystore: hive.site['hive.server2.keystore.path']
          storepass: hive.site['hive.server2.keystore.password']
          caname: "hive_root_ca"
          cacert: "#{tmp_location}/#{path.basename ssl.cacert}"
          key: "#{tmp_location}/#{path.basename ssl.key}"
          cert: "#{tmp_location}/#{path.basename ssl.cert}"
          keypass: ssl_server['ssl.server.keystore.keypassword']
          name: @config.shortname
        @java_keystore_add
          keystore: hive.site['hive.server2.keystore.path']
          storepass: hive.site['hive.server2.keystore.password']
          caname: "hadoop_root_ca"
          cacert: "#{tmp_location}/#{path.basename ssl.cacert}"
        @remove
          destination: "#{tmp_location}/#{path.basename ssl.cacert}"
          shy: true
        @remove
          destination: "#{tmp_location}/#{path.basename ssl.cert}"
          shy: true
        @remove
          destination: "#{tmp_location}/#{path.basename ssl.key}"
          shy: true
        @service
          srv_name: 'hive-server2'
          action: 'restart'
          if: -> @status()

## Kerberos

    module.exports.push header: 'Hive Server2 # Kerberos', handler: ->
      {hive, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: hive.site['hive.server2.authentication.kerberos.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: hive.site['hive.server2.authentication.kerberos.keytab']
        uid: hive.user.name
        gid: hive.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
        unless: @has_module('ryba/hive/hcatalog') and hive.site['hive.metastore.kerberos.principal'] is hive.site['hive.server2.authentication.kerberos.principal']

## Logs

    module.exports.push header: 'Hive Server2 # Logs', handler: ->
      @write
        source: "#{__dirname}/../../resources/hive/hive-exec-log4j.properties.template"
        local_source: true
        destination: '/etc/hive/conf/hive-exec-log4j.properties'
      @write
        source: "#{__dirname}/../../resources/hive/hive-log4j.properties.template"
        local_source: true
        destination: '/etc/hive/conf/hive-log4j.properties'

## Limits

    module.exports.push header: 'Hive Server2 : Limits', handler: ->
      {hive} = @config.ryba
      @system_limits
        user: hive.user.name
        nofile: 64000
        nproc: 64000
      
## Dependencies

    path = require 'path'
