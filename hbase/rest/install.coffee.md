
# HBase Rest Gateway Install

Note, Hortonworks recommand to grant administrative access to the _acl_ table
for the service princial define by "hbase.rest.kerberos.principal". For example,
run the command `grant '$USER', 'RWCA'`. Ryba isnt doing it because we didn't
have usecase for it yet.

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/java'
    module.exports.push 'ryba/hadoop/core'
    module.exports.push 'ryba/hbase'
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../../lib/hdp_service'
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
      ctx.hdp_service
        name: 'hbase-rest'
        version_name: 'hbase-client'
        write: [
          match: /^\. \/etc\/default\/hbase .*$/m
          replace: '. /etc/default/hbase # RYBA FIX rc.d, DONT OVERWRITE'
          append: ". /lib/lsb/init-functions"
        ,
          # HDP default is "/etc/hbase/conf"
          match: /^CONF_DIR=.*$/m
          replace: "CONF_DIR=\"${HBASE_CONF_DIR}\" # RYBA HONORS /etc/default, DONT OVEWRITE"
        ,
          # HDP default is "/usr/lib/hbase/bin/hbase-daemon.sh"
          match: /^EXEC_PATH=.*$/m
          replace: "EXEC_PATH=\"${HBASE_HOME}/bin/hbase-daemon.sh\" # RYBA HONORS /etc/default, DONT OVEWRITE"
        ,
          # HDP default is "/var/lib/hive-hcatalog/hcat.pid"
          match: /^PIDFILE=.*$/m
          replace: "PIDFILE=\"${HBASE_PID_DIR}/hbase-hbase-rest.pid\" # RYBA HONORS /etc/default, DONT OVEWRITE"
        ]
        etc_default:
          'hadoop': true
          'hbase':
            write: [
              match: /^export HBASE_HOME=.*$/m # HDP default is "/var/lib/hive-hcatalog"
              replace: "export HBASE_HOME=/usr/hdp/current/hbase-client # RYBA FIX"
            ]
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
      ctx
      .hconfigure
        destination: "#{hbase.conf_dir}/hbase-site.xml"
        default: "#{__dirname}/../../resources/hbase/hbase-site.xml"
        local_default: true
        properties: hbase.site
        merge: true
        uid: hbase.user.name
        gid: hbase.group.name
        backup: true
      .then next



