
# HBase Master Install

TODO: [HBase backup node](http://willddy.github.io/2013/07/02/HBase-Add-Backup-Master-Node.html)

    module.exports =  header: 'HBase Master Install', handler: ->
      {hadoop_group, hbase, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]

## IPTables

| Service             | Port  | Proto | Info                   |
|---------------------|-------|-------|------------------------|
| HBase Master        | 60000 | http  | hbase.master.port      |
| HMaster Info Web UI | 60010 | http  | hbase.master.info.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @iptables
        header: 'HBase Master # IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.master.site['hbase.master.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.master.site['hbase.master.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Info Web UI" }
        ]
        if: @config.iptables.action is 'start'

## HBase Master Layout

      @call header: 'HBase Master # Layout', timeout: -1, handler: ->
        @mkdir
          destination: hbase.master.pid_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755
        @mkdir
          destination: hbase.master.log_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755
        @mkdir
          destination: hbase.master.conf_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755

## Service

Install the "hbase-master" service, symlink the rc.d startup script inside
"/etc/init.d" and activate it on startup.

      @call header: 'HBase Master # Service', timeout: -1, handler: ->
        @service
          name: 'hbase-master'
        @hdp_select
          name: 'hbase-client'
        @hdp_select
          name: 'hbase-master'
        @render
          source: "#{__dirname}/../resources/hbase-master"
          local_source: true
          context: @config
          destination: '/etc/init.d/hbase-master'
          mode: 0o0755
          unlink: true
        @service_restart
          name: 'hbase-master'
          if: -> @status -4

## Configure

*   [New Security Features in Apache HBase 0.98: An Operator's Guide][secop].

[secop]: http://fr.slideshare.net/HBaseCon/features-session-2

      @hconfigure
        header: 'HBase Master # Configure'
        destination: "#{hbase.master.conf_dir}/hbase-site.xml"
        default: "#{__dirname}/../resources/hbase-site.xml"
        local_default: true
        properties: hbase.master.site
        merge: false
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o0600 # See slide 33 from [Operator's Guide][secop]
        backup: true

## Opts

Environment passed to the Master before it starts.

      @call header: 'HBase Master # Opts', handler: ->
        {hbase} = @config.ryba
        writes = for k, v of hbase.master.env
          match: RegExp "export #{k}=.*", 'm'
          replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
          append: true
        @render
          source: "#{__dirname}/../resources/hbase-env.sh"
          destination: "#{hbase.master.conf_dir}/hbase-env.sh"
          backup: true
          local_source: true
          eof: true
          context: @config
          uid: hbase.user.name
          gid: hbase.group.name
          write: writes
        #  match: /^export HBASE_ROOT_LOGGER=.*$/mg
        #  replace: "export HBASE_ROOT_LOGGER=#{hbase.master.log4j.root_logger}"
        #  append: true
        #  match: /^export HBASE_SECURITY_LOGGER=.*$/mg
        #  replace: "export HBASE_SECURITY_LOGGER=#{hbase.master.log4j.security_logger}"
        #  append: true

## RegionServers

Upload the list of registered RegionServers.

      @call header: 'HBase Master # RegionServers', timeout: -1, handler: ->
        {hbase, hadoop_group} = @config.ryba
        @write
          content: @hosts_with_module('ryba/hbase/regionserver').join '\n'
          destination: "#{hbase.master.conf_dir}/regionservers"
          uid: hbase.user.name
          gid: hadoop_group.name
          eof: true


## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master,
RegionServer, and HBase client host machines.

Environment file is enriched by "ryba/hbase" # HBase # Env".

      @call header: 'HBase Master # Zookeeper JAAS', timeout: -1, handler: ->
        @write_jaas
          destination: "#{hbase.master.conf_dir}/hbase-master.jaas"
          content: Client:
            principal: hbase.master.site['hbase.master.kerberos.principal'].replace '_HOST', @config.host
            keyTab: hbase.master.site['hbase.master.keytab.file']
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o700

## Kerberos

https://blogs.apache.org/hbase/entry/hbase_cell_security
https://hbase.apache.org/book/security.html

      @call header: 'HBase Master # Kerberos', handler: ->
        @krb5_addprinc
          principal: hbase.master.site['hbase.master.kerberos.principal'].replace '_HOST', @config.host
          randkey: true
          keytab: hbase.master.site['hbase.master.keytab.file']
          uid: hbase.user.name
          gid: hadoop_group.name
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: admin_server

      @call header: 'HBase Master # Kerberos Admin', handler: ->
        @krb5_addprinc
          principal: hbase.admin.principal
          password: hbase.admin.password
          kadmin_principal: kadmin_principal
          kadmin_password: kadmin_password
          kadmin_server: admin_server

      @call header: 'HBase Master # Log4J', handler: ->
        @write
          destination: "#{hbase.master.conf_dir}/log4j.properties"
          source: "#{__dirname}/../resources/log4j.properties"
          local_source: true

## Metrics

Enable stats collection in Ganglia and Graphite

      @call header: 'HBase Master # Metrics', handler: ->
        @write_properties
          destination: "#{hbase.master.conf_dir}/hadoop-metrics2-hbase.properties"
          content: hbase.metrics.config
          backup: true

      # @call header: 'HBase Master # SSL', retry: 0, handler: ->
      #   {ssl, ssl_server, ssl_client, hdfs} = @config.ryba
      #   ssl_client['ssl.client.truststore.location'] = "#{hbase.conf_dir}/truststore"
      #   ssl_server['ssl.server.keystore.location'] = "#{hbase.conf_dir}/keystore"
      #   ssl_server['ssl.server.truststore.location'] = "#{hbase.conf_dir}/truststore"
      #   @hconfigure
      #     destination: "#{hbase.conf_dir}/ssl-server.xml"
      #     properties: ssl_server
      #   @hconfigure
      #     destination: "#{hbase.conf_dir}/ssl-client.xml"
      #     properties: ssl_client
      #   # Client: import certificate to all hosts
      #   @java_keystore_add
      #     keystore: ssl_client['ssl.client.truststore.location']
      #     storepass: ssl_client['ssl.client.truststore.password']
      #     caname: "hadoop_root_ca"
      #     cacert: "#{ssl.cacert}"
      #     local_source: true
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
      #     local_source: true
      #   @java_keystore_add
      #     keystore: ssl_server['ssl.server.keystore.location']
      #     storepass: ssl_server['ssl.server.keystore.password']
      #     caname: "hadoop_root_ca"
      #     cacert: "#{ssl.cacert}"
      #     local_source: true

## SPNEGO

Ensure we have read access to the spnego keytab soring the server HTTP
principal.

      @call header: 'HBase Master # SPNEGO', handler: ->
        @execute
          cmd: "su -l #{hbase.user.name} -c 'test -r /etc/security/keytabs/spnego.service.keytab'"

# User limits

      @call header: 'HBase Master # Limits', handler: ->
        @system_limits
          user: hbase.user.name
          nofile: hbase.user.limits.nofile
          nproc: hbase.user.limits.nproc

# Dependencies

    path = require 'path'
    quote = require 'regexp-quote'
