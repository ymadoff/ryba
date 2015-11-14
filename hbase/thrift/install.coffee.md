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

    module.exports.push name: 'HBase Thrift # IPTables', handler: ->
      {hbase} = @config.ryba
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.thrift.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Thrift Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.thrift.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Thrift Info Web UI" }
        ]
        if: @config.iptables.action is 'start'

## ACL Table

      module.exports.push name: 'HBase Thrift # ACL Table', handler: ->
        {hbase} = @config.ryba
        @execute
          cmd: mkcmd.hbase @, """
          hbase shell 2>/dev/null <<-CMD
            grant 'hbase_thrift', 'RWCA'
          CMD
          """
          unless: hbase.site['hbase.thrift.kerberos.principal'].indexOf 'HTTP' > -1

# ## Kerberos
#
#     module.exports.push name: 'HBase Thrift # Kerberos', skip:true, handler: ->
#       {hadoop_group, hbase, realm} = @config.ryba
#       {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
#       @krb5_addprinc
#         principal: hbase.site['hbase.thrift.kerberos.principal'].replace '_HOST', @config.host
#         randkey: true
#         keytab: hbase.site['hbase.thrift.keytab.file']
#         uid: hbase.user.name
#         gid: hadoop_group.name
#         kadmin_principal: kadmin_principal
#         kadmin_password: kadmin_password
#         kadmin_server: admin_server


## Configure

Note, we left the permission mode as default, Master and RegionServer need to
restrict it but not the thrift server.

    module.exports.push name: 'HBase Thrift # Configure', handler: ->
      {hbase} = @config.ryba
      console.log
      @hconfigure
        destination: "#{hbase.conf_dir}/hbase-site.xml"
        default: "#{__dirname}/../resources/hbase-site.xml"
        local_default: true
        properties: hbase.site
        merge: true
        uid: hbase.user.name
        gid: hbase.group.name
        backup: true

## Hbase-Thrift Service

    module.exports.push name: 'HBase Thrift # Service', handler: ->
      {hbase} = @config.ryba
      @service
        name: 'hbase-thrift'
      @hdp_select
        name: 'hbase-client'
      @write
        source: "#{__dirname}/../resources/hbase-thrift"
        local_source: true
        destination: '/etc/init.d/hbase-thrift'
        mode: 0o0755
        unlink: true
      @execute
        cmd: "service hbase-thrift restart"
        if: -> @status -3

## Dependecies

    url = require 'url'
