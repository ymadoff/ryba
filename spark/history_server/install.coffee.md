# Apache Spark History Server

The history servers comes with the spark-client package. The single difference is in the configuration 
for  kerberos properties.



    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/spark/client'
    module.exports.push require('./index').configure

## Spark History Server Configure

    module.exports.push name: 'Spark History Server # Kerberos',  handler: (ctx, next) ->
      {spark} = ctx.config.ryba
      ctx
        destination: "#{spark.conf_dir}/spark-defaults.conf"
        write: [
          match: /^spark\.history\.kerberos\.enabled.*$/m
          replace: "spark.history.kerberos.enabled #{spark.history_server.isKerberos}"# Modified by RYBA Spark History Server Install
          append: true
        ,
          match: /^spark\.history\.kerberos\.principal.*$/m
          replace: "spark.history.kerberos.principal spark"# Modified by RYBA Spark History Server Install
          append: true
        ,
          match: /^spark\.history\.kerberos\.keytab.*$/m
          replace: "spark.history.kerberos.keytab /etc/security/keytabs/spark.keytab"# Modified by RYBA Spark History Server Install
          append:true
        
      ]
      backup: true
    , (err, executed) ->
      next err, true

## Kerberos

    module.exports.push name: 'Spark History Server # Kerberos', handler: (ctx, next) ->
      {hadoop_group, realm, spark} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: "spark/#{ctx.config.host}@#{realm}"
        randkey: true
        keytab: "/etc/security/keytabs/spark.keytab"
        uid: spark.user.name
        gid: hadoop_group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      , next






      

    



      
      
    

