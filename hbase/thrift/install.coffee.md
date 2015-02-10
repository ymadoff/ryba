

    module.exports.push name: 'HBase Rest # Kerberos', handler: (ctx, next) ->
      {hadoop_group, hbase, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: hbase.site['hbase.thrift.kerberos.principal'].replace '_HOST', ctx.config.host
        randkey: true
        keytab: hbase.site['hbase.thrift.keytab.file']
        uid: hbase.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next

TODO:

| Service                    | Port | Proto | Info                   |
|----------------------------|------|-------|------------------------|
| HBase Thrift Server        | 9090 | http  | hbase.thrift.port      |
| HBase Thrift Server Web UI | 9095 | http  | hbase.thrift.info.port |
