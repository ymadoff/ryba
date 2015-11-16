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
    # module.exports.push require('./index').configure
    module.exports.push 'ryba/spark/default'

## IPTables

| Service              | Port  | Proto | Info              |
|----------------------|-------|-------|-------------------|
| spark history server | 18080 | http  | Spark HTTP server |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    module.exports.push header: 'Spark Server # IPTables', handler: ->
      {spark} = @config.ryba
      @iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: spark.conf['spark.history.ui.port'], protocol: 'tcp', state: 'NEW', comment: "Oozie HTTP Server" }
        ]
        if: @config.iptables.action is 'start'

    module.exports.push header: 'Spark HS # Layout', handler: ->
      {spark} = @config.ryba
      @mkdir
        destination: spark.pid_dir
        uid: spark.user.name
        gid: spark.group.name
      @mkdir
        destination: spark.log_dir
        uid: spark.user.name
        gid: spark.group.name

## Spark History Server Configure

    module.exports.push header: 'Spark HS # Configuration',  handler: ->
      {java_home} = @config.java
      {spark} = @config.ryba
      @write
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
      @write
        destination: "#{spark.conf_dir}/spark-defaults.conf"
        write: for k, v of spark.conf
          match: ///^#{quote k}\ .*$///mg
          replace: if v is null then "" else "#{k} #{v}"
          append: v isnt null
        backup: true

## Kerberos

    module.exports.push header: 'Spark HS # Kerberos', handler: ->
      {spark, realm} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      @krb5_addprinc
        principal: spark.conf['spark.history.kerberos.principal']
        keytab: spark.conf['spark.history.kerberos.keytab']
        randkey: true
        uid: spark.user.name
        gid: spark.group.name
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        kadmin_server: admin_server

## Dependencies

    path = require 'path'
    quote = require 'regexp-quote'
    mkcmd = require '../../lib/mkcmd'
