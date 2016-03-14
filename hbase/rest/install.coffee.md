
# HBase Rest Gateway Install

Note, Hortonworks recommand to grant administrative access to the _acl_ table
for the service princial define by "hbase.rest.kerberos.principal". For example,
run the command `grant '$USER', 'RWCA'`. Ryba isnt doing it because we didn't
have usecase for it yet.
    
    module.exports =  header: 'HBase Rest Install', handler: ->
      {hadoop_group, hbase, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]

## IPTables

| Service                    | Port  | Proto | Info                   |
|----------------------------|-------|-------|------------------------|
| HBase REST Server          | 60080 | http  | hbase.rest.port        |
| HBase REST Server Web UI   | 60085 | http  | hbase.rest.info.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @iptables
        header: 'Iptables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.rest.site['hbase.rest.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.rest.site['hbase.rest.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Info Web UI" }
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

## HBase Rest Server Layout

      @call header: 'HBase Rest # Layout', timeout: -1, handler: ->
        @mkdir
          destination: hbase.rest.pid_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755
        @mkdir
          destination: hbase.rest.log_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755
        @mkdir
          destination: hbase.rest.conf_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755

## HBase Rest Service

      @call header: 'Service', handler: ->
        @service
          name: 'hbase-rest'
        @hdp_select
          name: 'hbase-client'
        @render
          header: 'Init Script'
          source: "#{__dirname}/../resources/hbase-rest"
          local_source: true
          context: @config
          destination: '/etc/init.d/hbase-rest'
          mode: 0o0755
          unlink: true
        @execute
          cmd: "service hbase-rest restart"
          if: -> @status -3

## Configure

Note, we left the permission mode as default, Master and RegionServer need to
restrict it but not the rest server.

      @hconfigure
        header: 'HBase Site'
        destination: "#{hbase.rest.conf_dir}/hbase-site.xml"
        default: "#{__dirname}/../resources/hbase-site.xml"
        local_default: true
        properties: hbase.rest.site
        merge: false
        uid: hbase.user.name
        gid: hbase.group.name
        backup: true
        
## Env

Environment passed to the HBase Rest Server before it starts.

      @render
        header: 'Hbase Env'
        source: "#{__dirname}/../resources/hbase-env.sh"
        destination: "#{hbase.rest.conf_dir}/hbase-env.sh"
        local_source: true
        context: @config
        mode: 0o0755
        uid: hbase.user.name
        gid: hbase.group.name
        unlink: true
        write: for k, v of hbase.rest.env
          match: RegExp "export #{k}=.*", 'm'
          replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"          

## Kerberos

Create the Kerberos keytab for the service principal.

      @krb5_addprinc
        header: 'Kerberos'
        principal: hbase.rest.site['hbase.rest.kerberos.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: hbase.rest.site['hbase.rest.keytab.file']
        uid: hbase.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

# User limits

      @system_limits
        user: hbase.user.name
        nofile: hbase.user.limits.nofile
        nproc: hbase.user.limits.nproc

## Logging

      @write
        header: 'Log4J'
        destination: "#{hbase.rest.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local_source: true
