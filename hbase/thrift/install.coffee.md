# HBase Thrift Gateway

Note, Hortonworks recommand to grant administrative access to the _acl_ table
for the service princial define by "hbase.thirft.kerberos.principal". For example,
run the command `grant '$USER', 'RWCA'`. Ryba isnt doing it because we didn't
have usecase for it yet.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/java'
    module.exports.push 'ryba/hadoop/core'
    module.exports.push 'ryba/hbase'
    # module.exports.push require('./index').configure
    module.exports.push 'ryba/lib/hconfigure'
    module.exports.push 'ryba/lib/hdp_select'

## IPTables

| Service                    | Port | Proto | Info                   |
|----------------------------|------|-------|------------------------|
| HBase Thrift Server        | 9090 | http  | hbase.thrift.port      |
| HBase Thrift Server Web UI | 9095 | http  | hbase.thrift.info.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push header: 'HBase Thrift # IPTables', handler: ->
      {hbase} = @config.ryba
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.thrift.site['hbase.thrift.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Thrift Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.thrift.site['hbase.thrift.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Thrift Info Web UI" }
        ]
        if: @config.iptables.action is 'start'


### Kerberos
#
#    module.exports.push header: 'HBase Thrift # Kerberos', handler: ->
#      {hadoop_group, hbase, realm} = @config.ryba
#      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
#      @krb5_addprinc
#        principal: hbase.site['hbase.thrift.kerberos.principal'].replace '_HOST', @config.host
#        randkey: true
#        keytab: hbase.site['hbase.thrift.keytab.file']
#        uid: hbase.user.name
#        gid: hadoop_group.name
#        kadmin_principal: kadmin_principal
#        kadmin_password: kadmin_password
#        kadmin_server: admin_server


## HBase Thrift Server Layout

    module.exports.push header: 'HBase Thrift # Layout', timeout: -1, handler: ->
      {hbase} = @config.ryba
      @mkdir
        destination: hbase.thrift.pid_dir
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o0755
      @mkdir
        destination: hbase.thrift.log_dir
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o0755
      @mkdir
        destination: hbase.thrift.conf_dir
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o0755

## ACL Table

      module.exports.push header: 'HBase Thrift # ACL Table', handler: ->
        {hbase} = @config.ryba
        @execute
          cmd: mkcmd.hbase @, """
          hbase shell 2>/dev/null <<-CMD
            grant 'hbase_thrift', 'RWCA'
          CMD
          """
          unless: hbase.thrift.site['hbase.thrift.kerberos.principal'].indexOf 'HTTP' > -1

## Configure

Note, we left the permission mode as default, Master and RegionServer need to
restrict it but not the thrift server.

    module.exports.push header: 'HBase Thrift # Configure', handler: ->
      {hbase} = @config.ryba
      @hconfigure
        destination: "#{hbase.thrift.conf_dir}/hbase-site.xml"
        default: "#{__dirname}/../resources/hbase-site.xml"
        local_default: true
        properties: hbase.thrift.site
        merge: false
        uid: hbase.user.name
        gid: hbase.group.name
        backup: true

# User limits

    module.exports.push header: 'HBase Thrift # Limits', handler: ->
      {hbase} = @config.ryba
      @system_limits
        user: hbase.user.name
        nofile: hbase.user.limits.nofile
        nproc: hbase.user.limits.nproc

## Opts

Environment passed to the HBase Rest Server before it starts.

    module.exports.push
      header: 'HBase Thrift # Opts'
      handler: ->
        {hbase} = @config.ryba
        writes = for k, v of hbase.thrift.env
          match: RegExp "export #{k}=.*", 'm'
          replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
        @render
          source: "#{__dirname}/../resources/hbase-env.sh"
          destination: "#{hbase.thrift.conf_dir}/hbase-env.sh"
          local_source: true
          context: @config
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755
          unlink: true
        @write
          destination: "#{hbase.thrift.conf_dir}/hbase-env.sh"
          backup: true
          write: writes

##  Hbase-Thrift Service

    module.exports.push header: 'HBase Thrift # Service', handler: ->
      {hbase} = @config.ryba
      @service
        name: 'hbase-thrift'
      @hdp_select
        name: 'hbase-client'
      @render
        source: "#{__dirname}/../resources/hbase-thrift"
        local_source: true
        context: @config
        destination: '/etc/init.d/hbase-thrift'
        mode: 0o0755
        unlink: true
      @execute
        cmd: "service hbase-thrift restart"
        if: -> @status -3

## Logging

    module.exports.push header: 'HBase Thrift # Log4J', handler: ->
      {hbase} = @config.ryba
      @write
        destination: "#{hbase.thrift.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local_source: true

## Dependecies

    url = require 'url'
