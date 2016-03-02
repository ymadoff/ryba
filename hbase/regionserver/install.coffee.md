
# HBase RegionServer Install

    module.exports = header: 'HBase RegionServer Install', handler: ->
      {hadoop_group, hbase, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]

## IPTables

| Service                      | Port  | Proto | Info                         |
|------------------------------|-------|-------|------------------------------|
| HBase Region Server          | 60020 | http  | hbase.regionserver.port      |
| HMaster Region Server Web UI | 60030 | http  | hbase.regionserver.info.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).
      
      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.rs.site['hbase.regionserver.port'], protocol: 'tcp', state: 'NEW', comment: "HBase RegionServer" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.rs.site['hbase.regionserver.info.port'], protocol: 'tcp', state: 'NEW', comment: "HBase RegionServer Info Web UI" }
        ]
        if: @config.iptables.action is 'start'

## HBase Regionserver Layout

      @call header: 'Layout', timeout: -1, handler: ->
        @mkdir
          destination: hbase.rs.pid_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755
        @mkdir
          destination: hbase.rs.log_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755
        @mkdir
          destination: hbase.rs.conf_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755

## Service

Install the "hbase-regionserver" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

      @call header: 'Service', timeout: -1, handler: ->
        @service
          name: 'hbase-regionserver'
        @hdp_select
          name: 'hbase-client'
        @hdp_select
          name: 'hbase-regionserver'
        @render
          header: 'Init Script'
          source: "#{__dirname}/../resources/hbase-regionserver"
          local_source: true
          context: @config
          destination: '/etc/init.d/hbase-regionserver'
          mode: 0o0755
          unlink: true
        @execute
          cmd: "service hbase-regionserver restart"
          if: -> @status -4

## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master,
RegionServer, and HBase client host machines.

      @write_jaas
        header: 'Zookeeper JAAS'
        destination: "#{hbase.rs.conf_dir}/hbase-regionserver.jaas"
        content: Client:
          principal: hbase.rs.site['hbase.regionserver.kerberos.principal'].replace '_HOST', @config.host
          keyTab: hbase.rs.site['hbase.regionserver.keytab.file']
        uid: hbase.user.name
        gid: hbase.group.name

## Kerberos
      
      @call header: 'Kerberos',  timeout: -1, handler: ->
        if @has_module 'ryba/hbase/master'
          if hbase.master.site['hbase.master.kerberos.principal'] isnt hbase.rs.site['hbase.regionserver.kerberos.principal']
            return throw Error "HBase principals must match in single node"
          @copy
            source: hbase.master.site['hbase.master.keytab.file']
            destination: hbase.rs.site['hbase.regionserver.keytab.file']
        else
          @krb5_addprinc
            principal: hbase.rs.site['hbase.regionserver.kerberos.principal'].replace '_HOST', @config.host
            randkey: true
            keytab: hbase.rs.site['hbase.regionserver.keytab.file']
            uid: hbase.user.name
            gid: hadoop_group.name
            kadmin_principal: kadmin_principal
            kadmin_password: kadmin_password
            kadmin_server: admin_server

## Configure

*   [New Security Features in Apache HBase 0.98: An Operator's Guide][secop].

[secop]: http://fr.slideshare.net/HBaseCon/features-session-2
  
      @call header: 'Configure', handler: ->
        @hconfigure
          header: 'Site'
          destination: "#{hbase.rs.conf_dir}/hbase-site.xml"
          default: "#{__dirname}/../resources/hbase-site.xml"
          local_default: true
          properties: hbase.rs.site
          merge: false
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0600 # See slide 33 from [Operator's Guide][secop]
          backup: true

## Opts

Environment passed to the RegionServer before it starts.

        writes = for k, v of hbase.rs.env
          match: RegExp "export #{k}=.*", 'm'
          replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
          append: true
        @render
          header: 'Opts'
          source: "#{__dirname}/../resources/hbase-env.sh"
          destination: "#{hbase.rs.conf_dir}/hbase-env.sh"
          backup: true
          uid: hbase.user.name
          gid: hbase.group.name
          local_source: true
          context: @config
          write: writes
          unlink: true
          eof: true

## RegionServers

Upload the list of registered RegionServers.
    
      @write
        header: 'Registered RegionServers'
        content: @hosts_with_module('ryba/hbase/regionserver').join '\n'
        destination: "#{hbase.rs.conf_dir}/regionservers"
        uid: hbase.user.name
        gid: hadoop_group.name
        eof: true

## Metrics

Enable stats collection in Ganglia and Graphite

      @write_properties
        header: 'Metrics'
        destination: "#{hbase.rs.conf_dir}/hadoop-metrics2-hbase.properties"
        content: hbase.metrics.config
        backup: true

# User limits

      @system_limits
        user: hbase.user.name
        nofile: hbase.user.limits.nofile
        nproc: hbase.user.limits.nproc

## Logging

      @write
        header: 'Log4J'
        destination: "#{hbase.rs.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local_source: true


# Module dependencies

    quote = require 'regexp-quote'
