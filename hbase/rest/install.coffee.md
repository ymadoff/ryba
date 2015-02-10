
# HBase Rest Server

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/java'
    module.exports.push 'ryba/hadoop/core_ssl'
    module.exports.push 'ryba/hbase/_'
    module.exports.push require('./index').configure

## IPTables

| Service                    | Port  | Proto | Info                   |
|----------------------------|-------|-------|------------------------|
| HBase REST Server          | 60080 | http  | hbase.rest.port        |
| HBase REST Server Web UI   | 60085 | http  | hbase.rest.info.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'HBase Rest # IPTables', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.rest.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.site['hbase.rest.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Info Web UI" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

    module.exports.push name: 'HBase Rest # Service', handler: (ctx, next) ->
      ctx.service
        name: 'hbase-rest'
      , next

## Kerberos

Create the Kerberos keytab for the service principal.

    module.exports.push name: 'HBase Rest # Kerberos', handler: (ctx, next) ->
      {hadoop_group, hbase, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: hbase.site['hbase.rest.kerberos.principal'].replace '_HOST', ctx.config.host
        randkey: true
        keytab: hbase.site['hbase.rest.keytab.file']
        uid: hbase.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next

## Configure

Note, we left the permission mode as default, Master and RegionServer need to
restrict it but not the rest server.

    module.exports.push name: 'HBase Rest # Configure', handler: (ctx, next) ->
      {hbase} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{hbase.conf_dir}/hbase-site.xml"
        default: "#{__dirname}/../../resources/hbase/hbase-site.xml"
        local_default: true
        properties: hbase.site
        merge: true
        uid: hbase.user.name
        gid: hbase.group.name
        backup: true
      , next







