
# HBase Master Install

TODO: [HBase backup node](http://willddy.github.io/2013/07/02/HBase-Add-Backup-Master-Node.html)

    module.exports =  header: 'HBase Master Install', handler: ->
      hbase_regionservers = @contexts 'ryba/hbase/regionserver'
      {hadoop_group, hbase, realm} = @config.ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## IPTables

| Service             | Port  | Proto | Info                   |
|---------------------|-------|-------|------------------------|
| HBase Master        | 60000 | http  | hbase.master.port      |
| HMaster Info Web UI | 60010 | http  | hbase.master.info.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.master.site['hbase.master.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.master.site['hbase.master.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Info Web UI" }
        ]
        if: @config.iptables.action is 'start'

## Users & Groups

By default, the "hbase" package create the following entries:

```bash
cat /etc/passwd | grep hbase
hbase:x:492:492:HBase:/var/run/hbase:/bin/bash
cat /etc/group | grep hbase
hbase:x:492:
```

      @system.group hbase.group
      @system.user hbase.user


## HBase Master Layout

      @call header: 'Layout', timeout: -1, handler: ->
        @mkdir
          target: hbase.master.pid_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755
        @mkdir
          target: hbase.master.log_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755
        @mkdir
          target: hbase.master.conf_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755

## Service

Install the "hbase-master" service, symlink the rc.d startup script inside
"/etc/init.d" and activate it on startup.

      @call header: 'Service', timeout: -1, handler: (options) ->
        @service
          name: 'hbase-master'
        @hdp_select
          name: 'hbase-client'
        @hdp_select
          name: 'hbase-master'
        @service.init
          header: 'Init Script'
          source: "#{__dirname}/../resources/hbase-master.j2"
          local: true
          context: @config
          target: '/etc/init.d/hbase-master'
          mode: 0o0755
        @system.tmpfs
          if: -> (options.store['mecano:system:type'] in ['redhat','centos']) and (options.store['mecano:system:release'][0] is '7')
          mount: hbase.master.pid_dir
          uid: hbase.user.name
          gid: hbase.group.name
          perm: '0755'

## Configure

*   [New Security Features in Apache HBase 0.98: An Operator's Guide][secop].

[secop]: http://fr.slideshare.net/HBaseCon/features-session-2

      @hconfigure
        header: 'HBase Site'
        target: "#{hbase.master.conf_dir}/hbase-site.xml"
        source: "#{__dirname}/../resources/hbase-site.xml"
        local: true
        properties: hbase.master.site
        merge: false
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o0600 # See slide 33 from [Operator's Guide][secop]
        backup: true

## Opts

Environment passed to the Master before it starts.
      
      @call header: 'HBase Env', handler: ->
        hbase.master.java_opts += " -D#{k}=#{v}" for k, v of hbase.master.opts
        @render
          target: "#{hbase.master.conf_dir}/hbase-env.sh"
          source: "#{__dirname}/../resources/hbase-env.sh.j2"
          backup: true
          local_source: true
          eof: true
          context: @config
          mode: 0o750
          uid: hbase.user.name
          gid: hbase.group.name
          write: for k, v of hbase.master.env
            match: RegExp "export #{k}=.*", 'm'
            replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
            append: true
          #  match: /^export HBASE_ROOT_LOGGER=.*$/mg
          #  replace: "export HBASE_ROOT_LOGGER=#{hbase.master.log4j.root_logger}"
          #  append: true
          #  match: /^export HBASE_SECURITY_LOGGER=.*$/mg
          #  replace: "export HBASE_SECURITY_LOGGER=#{hbase.master.log4j.security_logger}"
          #  append: true

## RegionServers

Upload the list of registered RegionServers.

      @file
        header: 'Registered RegionServers'
        content: hbase_regionservers.map( (ctx) -> ctx.config.host ).join '\n'
        target: "#{hbase.master.conf_dir}/regionservers"
        uid: hbase.user.name
        gid: hadoop_group.name
        eof: true
        mode: 0o640

## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master,
RegionServer, and HBase client host machines.

Environment file is enriched by "ryba/hbase" # HBase # Env".

      @file.jaas
        header: 'Zookeeper JAAS'
        target: "#{hbase.master.conf_dir}/hbase-master.jaas"
        content: Client:
          principal: hbase.master.site['hbase.master.kerberos.principal'].replace '_HOST', @config.host
          keyTab: hbase.master.site['hbase.master.keytab.file']
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o600

## Kerberos

https://blogs.apache.org/hbase/entry/hbase_cell_security
https://hbase.apache.org/book/security.html

      @krb5_addprinc krb5,
        header: 'Kerberos Master User'
        principal: hbase.master.site['hbase.master.kerberos.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: hbase.master.site['hbase.master.keytab.file']
        uid: hbase.user.name
        gid: hadoop_group.name

      @krb5_addprinc krb5,
        header: 'Kerberos Admin User'
        principal: hbase.admin.principal
        password: hbase.admin.password

      @file
        header: 'Log4J Properties'
        target: "#{hbase.master.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local: true
        write: for k, v of hbase.master.log4j
          match: RegExp "#{k}=.*", 'm'
          replace: "#{k}=#{v}"
          append: true

## Metrics

Enable stats collection in Ganglia and Graphite

      @file.properties
        header: 'Metrics Properties'
        target: "#{hbase.master.conf_dir}/hadoop-metrics2-hbase.properties"
        content: hbase.metrics.config
        backup: true
        mode: 0o640

      # @call header: 'SSL', retry: 0, handler: ->
      #   {ssl, ssl_server, ssl_client, hdfs} = @config.ryba
      #   ssl_client['ssl.client.truststore.location'] = "#{hbase.conf_dir}/truststore"
      #   ssl_server['ssl.server.keystore.location'] = "#{hbase.conf_dir}/keystore"
      #   ssl_server['ssl.server.truststore.location'] = "#{hbase.conf_dir}/truststore"
      #   @hconfigure
      #     target: "#{hbase.conf_dir}/ssl-server.xml"
      #     properties: ssl_server
      #   @hconfigure
      #     target: "#{hbase.conf_dir}/ssl-client.xml"
      #     properties: ssl_client
      #   # Client: import certificate to all hosts
      #   @java_keystore_add
      #     keystore: ssl_client['ssl.client.truststore.location']
      #     storepass: ssl_client['ssl.client.truststore.password']
      #     caname: "hadoop_root_ca"
      #     cacert: "#{ssl.cacert}"
      #     local: true
      #   # Server: import certificates, private and public keys to hosts with a server
      #   @java_keystore_add
      #     keystore: ssl_server['ssl.server.keystore.location']
      #     storepass: ssl_server['ssl.server.keystore.password']
      #     caname: "hadoop_root_ca"
      #     cacert: "#{ssl.cacert}"
      #     key: "#{ssl.key}"
      #     cert: "#{ssl.cert}"
      #     keypass: ssl_server['ssl.server.keystore.keypassword']
      #     name: @config.shortname
      #     local: true
      #   @java_keystore_add
      #     keystore: ssl_server['ssl.server.keystore.location']
      #     storepass: ssl_server['ssl.server.keystore.password']
      #     caname: "hadoop_root_ca"
      #     cacert: "#{ssl.cacert}"
      #     local: true

## SPNEGO

Ensure we have read access to the spnego keytab soring the server HTTP
principal.


      @execute
        header: 'SPNEGO'
        cmd: "su -l #{hbase.user.name} -c 'test -r /etc/security/keytabs/spnego.service.keytab'"

# User limits

      @system.limits
        header: 'Ulimit'
        user: hbase.user.name
      , hbase.user.limits

## Ranger HBase Plugin Install

      @call
        if: -> @contexts('ryba/ranger/admin').length > 0
        handler: ->
          @call -> @config.ryba.hbase_plugin_is_master = true
          @call 'ryba/ranger/plugins/hbase/install'
          @call -> @config.ryba.hbase_plugin_is_master = false

# Dependencies

    path = require 'path'
    quote = require 'regexp-quote'
