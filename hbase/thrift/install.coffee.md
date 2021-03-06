# HBase Thrift Gateway

Note, Hortonworks recommand to grant administrative access to the _acl_ table
for the service princial define by "hbase.thirft.kerberos.principal". For example,
run the command `grant '$USER', 'RWCA'`. Ryba isnt doing it because we didn't
have usecase for it yet.

This installation also found inspiration from the 
[cloudera hbase setup in secure mode][hbase-configuration].

    module.exports =  header: 'HBase Thrift Install', handler: ->
      {hbase} = @config.ryba

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## IPTables

| Service                    | Port | Proto | Info                   |
|----------------------------|------|-------|------------------------|
| HBase Thrift Server        | 9090 | http  | hbase.thrift.port      |
| HBase Thrift Server Web UI | 9095 | http  | hbase.thrift.info.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.thrift.site['hbase.thrift.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Thrift Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.thrift.site['hbase.thrift.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Thrift Info Web UI" }
        ]
        if: @config.iptables.action is 'start'

## Identities

By default, the "hbase" package create the following entries:

```bash
cat /etc/passwd | grep hbase
hbase:x:492:492:HBase:/var/run/hbase:/bin/bash
cat /etc/group | grep hbase
hbase:x:492:
```

      @system.group header: 'Group', hbase.group
      @system.user header: 'User', hbase.user

## HBase Thrift Server Layout

      @call header: 'Layout', timeout: -1, ->
        @system.mkdir
          target: hbase.thrift.pid_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755
        @system.mkdir
          target: hbase.thrift.log_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755
        @system.mkdir
          target: hbase.thrift.conf_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755

## ACL Table

        @system.execute
          header: 'ACL Table'
          cmd: mkcmd.hbase @, """
          hbase shell 2>/dev/null <<-CMD
            grant 'hbase_thrift', 'RWCA'
          CMD
          """
          unless: hbase.thrift.site['hbase.thrift.kerberos.principal'].indexOf 'HTTP' > -1

## Configure

Note, we left the permission mode as default, Master and RegionServer need to
restrict it but not the thrift server.

      @hconfigure
        header: 'HBase Site'
        target: "#{hbase.thrift.conf_dir}/hbase-site.xml"
        source: "#{__dirname}/../resources/hbase-site.xml"
        local: true
        properties: hbase.thrift.site
        merge: false
        uid: hbase.user.name
        gid: hbase.group.name
        backup: true

## Opts

Environment passed to the HBase Rest Server before it starts.

      @file.render
        header: 'HBase Env'
        target: "#{hbase.thrift.conf_dir}/hbase-env.sh"
        source: "#{__dirname}/../resources/hbase-env.sh.j2"
        local: true
        context: @config
        mode: 0o0755
        unlink: true
        write: for k, v of hbase.thrift.env
          match: RegExp "export #{k}=.*", 'm'
          replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"  

# User limits

      @system.limits
        header: 'Ulimit'
        user: hbase.user.name
      , hbase.user.limits

##  Hbase-Thrift Service

      @call header: 'Service', (options) ->
        @service
          name: 'hbase-thrift'
        @hdp_select
          name: 'hbase-client'
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          header: 'Init Script'
          target: '/etc/init.d/hbase-thrift'
          source: "#{__dirname}/../resources/hbase-thrift.j2"
          local: true
          context: @config
          mode: 0o0755
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/hbase-thrift.service'
            source: "#{__dirname}/../resources/hbase-thrift-systemd.j2"
            local: true
            context: @config.ryba
            mode: 0o0640
          @system.tmpfs
            header: 'Run dir'
            mount: hbase.thrift.pid_dir
            uid: hbase.user.name
            gid: hbase.group.name
            perm: '0755'

## Logging

      @file
        header: 'Log4J'
        target: "#{hbase.thrift.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local: true

## Dependecies

    url = require 'url'
    mkcmd = require '../../lib/mkcmd'
