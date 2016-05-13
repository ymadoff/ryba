
# Hive Server2 Install

TODO: Implement lock for Hive Server2
http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Installation-Guide/cdh4ig_topic_18_5.html

HDP 2.1 and 2.2 dont support secured Hive metastore in HA mode, see
[HIVE-9622](https://issues.apache.org/jira/browse/HIVE-9622).

Resources:
*   [Cloudera security instruction for CDH5](http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_sg_hiveserver2_security.html)
    
    module.exports =  header: 'Hive Server2 Install', handler: ->
      {hive} = @config.ryba
      {java_home} = @config.java
      {ssl, ssl_server, ssl_client, hadoop_conf_dir, realm} = @config.ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      tmp_location = "/var/tmp/ryba/ssl"
      hive_server_port = if hive.site['hive.server2.transport.mode'] is 'binary'
      then hive.site['hive.server2.thrift.port']
      else hive.site['hive.server2.thrift.http.port']

## Register

      @register 'hconfigure', 'ryba/lib/hconfigure'
      @register 'hdp_select', 'ryba/lib/hdp_select'

## Wait

      @call once: true, 'ryba/hive/hcatalog/wait'

## IPTables

| Service        | Port  | Proto | Parameter            |
|----------------|-------|-------|----------------------|
| Hive Server    | 10001 | tcp   | env[HIVE_PORT]       |


IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hive_server_port, protocol: 'tcp', state: 'NEW', comment: "Hive Server" }
        ]
        if: @config.iptables.action is 'start'

## Users & Groups

By default, the "hive" and "hive-hcatalog" packages create the following
entries:

```bash
cat /etc/passwd | grep hive
hive:x:493:493:Hive:/var/lib/hive:/sbin/nologin
cat /etc/group | grep hive
hive:x:493:
```

      @group hive.group
      @user hive.user
      
      
## Startup

Install the "hive-server2" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

The server is not activated on startup because they endup as zombies if HDFS
isnt yet started.

      @call header: 'Service', handler: ->
        @service
          name: 'hive'
        @service
          name: 'hive-server2'
        @hdp_select
          name: 'hive-server2'
        @write
          header: 'Init Script'
          source: "#{__dirname}/../resources/hive-server2.j2"
          local_source: true
          destination: '/etc/init.d/hive-server2'
          mode: 0o0755
          unlink: true
        @execute
          cmd: "service hive-server2 restart"
          if: -> @status -3

## Configuration

      @hconfigure
        header: 'Hive Site'
        destination: "#{hive.server2.conf_dir}/hive-site.xml"
        default: "#{__dirname}/../../resources/hive/hive-site.xml"
        local_default: true
        properties: hive.site
        merge: true
        backup: true
      @render
        header: 'Hive Log4j properties'
        source: "#{__dirname}/../resources/hive-exec-log4j.properties"
        local_source: true
        destination: '/etc/hive/conf/hive-exec-log4j.properties'
        context: @config
      @write_properties
        header: 'Hive server Log4j properties'
        destination: "/etc/hive/conf/hive-log4j.properties"
        content: hive.server.log4j.config
        backup: true

## Env

Enrich the "hive-env.sh" file with the value of the configuration property
"ryba.hive.server2.opts". Internally, the environmental variable
"HADOOP_CLIENT_OPTS" is enriched and only apply to the Hive Server2.

Using this functionnality, a user may for example raise the heap size of Hive
Server2 to 4Gb by setting a value equal to "-Xmx4096m".

      @write
        header: 'Hive Env Write'
        destination: "#{hive.server2.conf_dir}/hive-env.sh"
        source: "#{__dirname}/resources/hive-env.sh"
        local_source: true
        unless_exists: true
      @write
        header: 'Hive Env'
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
        write: [
          match: /^export JAVA_HOME=.*$/m
          replace: "export JAVA_HOME=#{java_home}"
        ,
          match: /^export HIVE_AUX_JARS_PATH=.*$/m
          replace: "export HIVE_AUX_JARS_PATH=${HIVE_AUX_JARS_PATH:-#{hive.aux_jars.join ':'}} # RYBA FIX"
        ]
        

## Layout

Create the directories to store the logs and pid information. The properties
"ryba.hive.server2.log\_dir" and "ryba.hive.server2.pid\_dir" may be modified.

      @call header: 'Layout', timeout: -1, handler: ->
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

      @call
        header: 'Client SSL'
        if: -> @config.ryba.hive.site['hive.server2.use.SSL'] is 'true'
        handler: ->
          @download
            source: ssl.cacert
            destination: "#{tmp_location}/#{path.basename ssl.cacert}"
            mode: 0o0600
            shy: true
          @download
            source: ssl.cert
            destination: "#{tmp_location}/#{path.basename ssl.cert}"
            mode: 0o0600
            shy: true
          @download
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
          # @java_keystore_add
          #   keystore: hive.site['hive.server2.keystore.path']
          #   storepass: hive.site['hive.server2.keystore.password']
          #   caname: "hadoop_root_ca"
          #   cacert: "#{tmp_location}/#{path.basename ssl.cacert}"
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

      @krb5_addprinc krb5,
        header: 'Kerberos'
        principal: hive.site['hive.server2.authentication.kerberos.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: hive.site['hive.server2.authentication.kerberos.keytab']
        uid: hive.user.name
        gid: hive.group.name
        unless: @has_module('ryba/hive/hcatalog') and hive.site['hive.metastore.kerberos.principal'] is hive.site['hive.server2.authentication.kerberos.principal']

## Ulimit

      @system_limits
        user: hive.user.name
        nofile: hive.user.limits.nofile
        nproc: hive.user.limits.nproc
      
## Dependencies

    path = require 'path'
