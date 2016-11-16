# HBase Thrift Gateway

Note, Hortonworks recommand to grant administrative access to the _acl_ table
for the service princial define by "hbase.thirft.kerberos.principal". For example,
run the command `grant '$USER', 'RWCA'`. Ryba isnt doing it because we didn't
have usecase for it yet.

This installation also found inspiration from the 
[cloudera hbase setup in secure mode][hbase-configuration].

    module.exports =  header: 'HBase Thrift Install',  handler: ->
      {hbase} = @config.ryba

## Register

      @register 'hconfigure', 'ryba/lib/hconfigure'
      @register 'hdp_select', 'ryba/lib/hdp_select'

## IPTables

| Service                    | Port | Proto | Info                   |
|----------------------------|------|-------|------------------------|
| HBase Thrift Server        | 9090 | http  | hbase.thrift.port      |
| HBase Thrift Server Web UI | 9095 | http  | hbase.thrift.info.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.thrift.site['hbase.thrift.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Thrift Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.thrift.site['hbase.thrift.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Thrift Info Web UI" }
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

      @group hbase.group
      @user hbase.user


### Kerberos

#    module.exports.push header: 'HBase Thrift # Kerberos', handler: ->
#      {hadoop_group, hbase, realm} = @config.ryba
#      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
#      @krb5_addprinc krb5,
#        principal: hbase.site['hbase.thrift.kerberos.principal'].replace '_HOST', @config.host
#        randkey: true
#        keytab: hbase.site['hbase.thrift.keytab.file']
#        uid: hbase.user.name
#        gid: hadoop_group.name


## HBase Thrift Server Layout

      @call header: 'Layout', timeout: -1, handler: ->
        @mkdir
          target: hbase.thrift.pid_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755
        @mkdir
          target: hbase.thrift.log_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755
        @mkdir
          target: hbase.thrift.conf_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755

## ACL Table

        @execute
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
        local_source: true
        properties: hbase.thrift.site
        merge: false
        uid: hbase.user.name
        gid: hbase.group.name
        backup: true

## Opts

Environment passed to the HBase Rest Server before it starts.

      @render
        header: 'HBase Env'
        target: "#{hbase.thrift.conf_dir}/hbase-env.sh"
        source: "#{__dirname}/../resources/hbase-env.sh.j2"
        local_source: true
        context: @config
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o0755
        unlink: true
        write: for k, v of hbase.thrift.env
          match: RegExp "export #{k}=.*", 'm'
          replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"  

# User limits

      @system_limits
        user: hbase.user.name
        nofile: hbase.user.limits.nofile
        nproc: hbase.user.limits.nproc

##  Hbase-Thrift Service

      @call header: 'Service', handler: ->
        @service
          name: 'hbase-thrift'
        @hdp_select
          name: 'hbase-client'
        @render
          header: 'Init Script'
          source: "#{__dirname}/../resources/hbase-thrift"
          local_source: true
          context: @config
          target: '/etc/init.d/hbase-thrift'
          mode: 0o0755
          unlink: true
        @execute
          cmd: "service hbase-thrift restart"
          if: -> @status -3

## Logging

      @file
        header: 'Log4J'
        target: "#{hbase.thrift.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local_source: true

## Dependecies

    url = require 'url'
    mkcmd = require '../../lib/mkcmd'
