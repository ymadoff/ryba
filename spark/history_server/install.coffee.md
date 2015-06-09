# Apache Spark History Server

The history servers comes with the spark-client package. The single difference is in the configuration
for  kerberos properties.



    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/spark/client'
    module.exports.push require('./index').configure

## Spark History Server Configure

    module.exports.push name: 'Spark HS # Configuration',  handler: (ctx, next) ->
      {spark, security} = ctx.config.ryba
      ctx
      .write
        destination: "#{spark.conf_dir}/spark-defaults.conf"
        write: [
          match: /^spark\.history\.kerberos\.enabled.*$/m
          replace: "spark.history.kerberos.enabled #{security is 'kerberos'} # RYBA CONF `security`, DON'T OVERWRITE"
          append: true
        ,
          match: /^spark\.history\.kerberos\.principal.*$/m
          replace: "spark.history.kerberos.principal #{spark.krb5_user.principal} # RYBA CONF `spark.krb5_user.principal`, DON'T OVERWRITE"
          append: true
        ,
          match: /^spark\.history\.kerberos\.keytab.*$/m
          replace: "spark.history.kerberos.keytab #{spark.krb5_user.keytab} # RYBA CONF `spark.krb5_user.keytab`, DON'T OVERWRITE"
          append:true
      ]
      backup: true
    .then next

## Kerberos

    module.exports.push name: 'Spark HS # Kerberos', handler: (ctx, next) ->
      {spark} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: spark.krb5_user.principal
        keytab: spark.krb5_user.keytab
        randkey: true
        uid: spark.user.name
        gid: spark.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      .then next
