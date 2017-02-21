
# HBase RegionServer Install

    module.exports = header: 'HBase RegionServer Install', handler: ->
      hbase_regionserver = @contexts 'ryba/hbase/regionserver'
      {hadoop_group, hbase, realm} = @config.ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      regionservers = hbase_regionserver.map( (ctx) -> ctx.config.host).join '\n'

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## IPTables

| Service                      | Port  | Proto | Info                         |
|------------------------------|-------|-------|------------------------------|
| HBase Region Server          | 60020 | http  | hbase.regionserver.port      |
| HMaster Region Server Web UI | 60030 | http  | hbase.regionserver.info.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.rs.site['hbase.regionserver.port'], protocol: 'tcp', state: 'NEW', comment: "HBase RegionServer" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.rs.site['hbase.regionserver.info.port'], protocol: 'tcp', state: 'NEW', comment: "HBase RegionServer Info Web UI" }
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


## HBase Regionserver Layout

      @call header: 'Layout', timeout: -1, handler: ->
        @system.mkdir
          target: hbase.rs.pid_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755
        @system.mkdir
          target: hbase.rs.log_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755
        @system.mkdir
          target: hbase.rs.conf_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755

## Service

Install the "hbase-regionserver" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

      @call header: 'Service', timeout: -1, handler: (options) ->
        @service
          name: 'hbase-regionserver'
        @hdp_select
          name: 'hbase-client'
        @hdp_select
          name: 'hbase-regionserver'
        @service.init
          header: 'Init Script'
          source: "#{__dirname}/../resources/hbase-regionserver.j2"
          local: true
          context: @config
          target: '/etc/init.d/hbase-regionserver'
          mode: 0o0755
        @system.tmpfs
          if: -> (options.store['mecano:system:type'] in ['redhat','centos']) and (options.store['mecano:system:release'][0] is '7')
          mount: hbase.rs.pid_dir
          uid: hbase.user.name
          gid: hbase.group.name
          perm: '0755'

## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master,
RegionServer, and HBase client host machines.

      @file.jaas
        header: 'Zookeeper JAAS'
        target: "#{hbase.rs.conf_dir}/hbase-regionserver.jaas"
        content: Client:
          principal: hbase.rs.site['hbase.regionserver.kerberos.principal'].replace '_HOST', @config.host
          keyTab: hbase.rs.site['hbase.regionserver.keytab.file']
        uid: hbase.user.name
        gid: hbase.group.name

## Kerberos

      @system.copy
        header: 'Copy Keytab'
        if: @has_service 'ryba/hbase/master'
        source: hbase.master.site['hbase.master.keytab.file']
        target: hbase.rs.site['hbase.regionserver.keytab.file']
      @krb5_addprinc krb5,
        header: 'Kerberos'
        unless: @has_service 'ryba/hbase/master'
        principal: hbase.rs.site['hbase.regionserver.kerberos.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: hbase.rs.site['hbase.regionserver.keytab.file']
        uid: hbase.user.name
        gid: hadoop_group.name

## Configure

*   [New Security Features in Apache HBase 0.98: An Operator's Guide][secop].

[secop]: http://fr.slideshare.net/HBaseCon/features-session-2

      @hconfigure
        header: 'HBase Site'
        target: "#{hbase.rs.conf_dir}/hbase-site.xml"
        source: "#{__dirname}/../resources/hbase-site.xml"
        local: true
        properties: hbase.rs.site
        merge: false
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o0600 # See slide 33 from [Operator's Guide][secop]
        backup: true

## Opts

Environment passed to the RegionServer before it starts.

      @call header: 'HBase Env', handler: ->
        hbase.rs.java_opts += " -D#{k}=#{v}" for k, v of hbase.rs.opts
        @file.render
          target: "#{hbase.rs.conf_dir}/hbase-env.sh"
          source: "#{__dirname}/../resources/hbase-env.sh.j2"
          backup: true
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o750
          local: true
          context: @config
          write: for k, v of hbase.rs.env
            match: RegExp "export #{k}=.*", 'm'
            replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
            append: true
          unlink: true
          eof: true

## RegionServers

Upload the list of registered RegionServers.

      @file
        header: 'Registered RegionServers'
        content: regionservers
        target: "#{hbase.rs.conf_dir}/regionservers"
        uid: hbase.user.name
        gid: hadoop_group.name
        eof: true
        mode: 0o0640

## Metrics

Enable stats collection in Ganglia and Graphite

      @file.properties
        header: 'Metrics'
        target: "#{hbase.rs.conf_dir}/hadoop-metrics2-hbase.properties"
        content: hbase.metrics.config
        backup: true
        mode: 0o0640

# User limits

      @system.limits
        header: 'Ulimit'
        user: hbase.user.name
      , hbase.user.limits

## Logging

      @file
        header: 'Log4J'
        target: "#{hbase.rs.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local: true
        write: for k, v of hbase.rs.log4j
          match: RegExp "#{k}=.*", 'm'
          replace: "#{k}=#{v}"
          append: true

## Ranger HBase Plugin Install

      @call
        if: -> @contexts('ryba/ranger/admin').length > 0
        handler: ->
          @call -> @config.ryba.hbase_plugin_is_master = false
          @call 'ryba/ranger/plugins/hbase/install'

# Module dependencies

    quote = require 'regexp-quote'
