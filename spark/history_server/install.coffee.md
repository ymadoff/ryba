# Apache Spark History Server

The history servers comes with the spark-client package. The single difference is in the configuration
for  kerberos properties.
We does not recommand using the spark WEB UI because it does not support SSL. Moreover it does make Yarn
redirect the tracking URL to the WEBUI which prevents the user to see the log after the job has finished
in the resource Manager web interface.



    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/commons/java'
    module.exports.push 'ryba/hadoop/hdfs_client'
    module.exports.push require('./index').configure
    module.exports.push 'ryba/spark/client/install'

## Spark Users And Group

By default, the "spark" package create the following entries:

```bash
cat /etc/passwd | grep spark
spark:x:495:494:Spark:/var/lib/spark:/bin/bash
cat /etc/group | grep spark
spark:x:494:
```

    module.exports.push name: 'Spark HS # Users & Groups', handler: (ctx, next) ->
      {spark} = ctx.config.ryba
      ctx
      .group spark.group
      .user spark.user
      .then next

## IPTables

| Service              | Port  | Proto | Info              |
|----------------------|-------|-------|-------------------|
| spark history server | 18080 | http  | Spark HTTP server |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push name: 'Oozie Server # IPTables', handler: (ctx, next) ->
      {spark} = ctx.config.ryba
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: spark.conf['spark.history.ui.port'], protocol: 'tcp', state: 'NEW', comment: "Oozie HTTP Server" }
        ]
        if: ctx.config.iptables.action is 'start'
      .then next

    module.exports.push name: 'Spark HS # Layout', handler: (ctx, next) ->
      {spark} = ctx.config.ryba
      fs_log_dir = spark.conf['spark.history.fs.logDirectory']
      fs_log_dir = if fs_log_dir.indexOf('file:/') is 0 then  path.join('/', fs_log_dir.substr(6)) else fs_log_dir
      ctx
      .mkdir
        destination: spark.pid_dir
        uid: spark.user.name
        gid: spark.group.name
      .mkdir
        destination: spark.log_dir
        uid: spark.user.name
        gid: spark.group.name
      .mkdir
        destination: fs_log_dir
        uid: spark.user.name
        gid: spark.group.name
        parent: true
      .then next

## Spark History Server Configure

    module.exports.push name: 'Spark HS # Configuration',  handler: (ctx, next) ->
      {java_home} = ctx.config.java
      {spark} = ctx.config.ryba
      ctx
      .write
        destination : "#{spark.conf_dir}/spark-env.sh"
        # See "/usr/hdp/current/spark-historyserver/sbin/spark-daemon.sh" for
        # additionnal environmental variables.
        write: [
          match :/^export SPARK_PID_DIR=.*$/mg
          replace:"export SPARK_PID_DIR=#{spark.pid_dir} # RYBA CONF \"ryba.spark.pid_dir\", DONT OVEWRITE"
          append: true
        ,
          match :/^export SPARK_CONF_DIR=.*$/mg
          # replace:"export SPARK_CONF_DIR=#{spark.conf_dir} # RYBA CONF \"ryba.spark.conf_dir\", DONT OVERWRITE"
          replace:"export SPARK_CONF_DIR=${SPARK_HOME:-/usr/hdp/current/spark-historyserver}/conf # RYBA CONF \"ryba.spark.conf_dir\", DONT OVERWRITE"
          append: true
        ,
          match :/^export SPARK_LOG_DIR=.*$/mg
          replace:"export SPARK_LOG_DIR=#{spark.log_dir} # RYBA CONF \"ryba.spark.log_dir\", DONT OVERWRITE"
          append: true
        ,
          match :/^export JAVA_HOME=.*$/mg
          replace:"export JAVA_HOME=#{java_home} # RYBA, DONT OVERWRITE"
          append: true
        ]
      .write
        destination: "#{spark.conf_dir}/spark-defaults.conf"
        write: for k, v of spark.conf
          match: ///^#{quote k}\ .*$///mg
          replace: if v is null then "" else "#{k} #{v}"
          append: v isnt null
        backup: true
      .then next

## Kerberos

    module.exports.push name: 'Spark HS # Kerberos', handler: (ctx, next) ->
      {spark, realm} = ctx.config.ryba
      {kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5.etc_krb5_conf.realms[realm]
      ctx.krb5_addprinc
        principal: spark.conf['spark.history.kerberos.principal']
        keytab: spark.conf['spark.history.kerberos.keytab']
        randkey: true
        uid: spark.user.name
        gid: spark.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server
      .then next

## Spark Files Permissions

    module.exports.push name: 'Spark HS # Permissions', handler: (ctx, next) ->
      {spark} = ctx.config.ryba
      ctx.execute
        cmd: mkcmd.hdfs ctx, """
          hdfs dfs -mkdir -p /user/#{spark.user.name}
          hdfs dfs -chown #{spark.user.name}:#{spark.group.name} /user/#{spark.user.name}
          hdfs dfs -chmod -R 755 /user/#{spark.user.name}
          """
      .then next

## Dependencies

    path = require 'path'
    quote = require 'regexp-quote'
    mkcmd = require '../../lib/mkcmd'
