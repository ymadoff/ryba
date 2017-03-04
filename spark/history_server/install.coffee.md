# Apache Spark History Server

The history servers comes with the spark-client package. The single difference 
is in the configuration for  kerberos properties.

We do not recommand using the spark WEB UI because it does not support SSL. 
Moreover it does make Yarn redirect the tracking URL to the WEBUI which prevents
the user to see the log after the job has finished in the YARN Resource Manager 
web interface.

    module.exports =  header: 'Spark History Server Install', handler: (options) ->
      {spark, realm, hadoop_group} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]
      {java_home} = @config.java

      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'
      @registry.register 'hconfigure', 'ryba/lib/hconfigure'

# Users and Groups   

      @system.group spark.group
      @system.user spark.user

# Packages

      @service
        name: 'spark'
      @hdp_select
        name: 'spark-historyserver'
      @service.init
        destination : "/etc/init.d/spark-history-server"
        source: "#{__dirname}/../resources/spark-history-server"
        local: true
        context: @config.ryba
        backup: true
        mode: 0o0755
      @system.tmpfs
        if: -> (options.store['nikita:system:type'] in ['redhat','centos']) and (options.store['nikita:system:release'][0] is '7')
        mount: spark.history.pid_dir
        uid: spark.user.name
        gid: spark.group.name
        perm: '0750'

# Layout

## IPTables

| Service              | Port  | Proto | Info              |
|----------------------|-------|-------|-------------------|
| spark history server | 18080 | http  | Spark HTTP server |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: spark.history.conf['spark.history.ui.port'], protocol: 'tcp', state: 'NEW', comment: "Oozie HTTP Server" }
        ]
        if: @config.iptables.action is 'start'

      @call header: 'Layout', handler: ->
        @system.mkdir
          target: spark.history.pid_dir
          uid: spark.user.name
          gid: spark.group.name
        @system.mkdir
          target: spark.history.log_dir
          uid: spark.user.name
          gid: spark.group.name
        @system.mkdir
          target: spark.history.conf_dir
          uid: spark.user.name
          gid: spark.group.name

## Spark History Server Configure

      @file
        header: 'Spark env'
        destination : "#{spark.history.conf_dir}/spark-env.sh"
        # See "/usr/hdp/current/spark-historyserver/sbin/spark-daemon.sh" for
        # additionnal environmental variables.
        write: [
          match :/^export SPARK_PID_DIR=.*$/mg
          replace:"export SPARK_PID_DIR=#{spark.history.pid_dir} # RYBA CONF \"ryba.spark.history.pid_dir\", DONT OVEWRITE"
          append: true
        ,
          match :/^export SPARK_CONF_DIR=.*$/mg
          # replace:"export SPARK_CONF_DIR=#{spark.conf_dir} # RYBA CONF \"ryba.spark.conf_dir\", DONT OVERWRITE"
          replace:"export SPARK_CONF_DIR=${SPARK_HOME:-/usr/hdp/current/spark-historyserver}/conf # RYBA CONF \"ryba.spark.conf_dir\", DONT OVERWRITE"
          append: true
        ,
          match :/^export SPARK_LOG_DIR=.*$/mg
          replace:"export SPARK_LOG_DIR=#{spark.history.log_dir} # RYBA CONF \"ryba.spark.log_dir\", DONT OVERWRITE"
          append: true
        ,
          match :/^export JAVA_HOME=.*$/mg
          replace:"export JAVA_HOME=#{java_home} # RYBA, DONT OVERWRITE"
          append: true
        ]
      @file
        header: 'Spark Defaults'
        target: "#{spark.history.conf_dir}/spark-defaults.conf"
        write: for k, v of spark.history.conf
          match: ///^#{quote k}\ .*$///mg
          replace: if v is null then "" else "#{k} #{v}"
          append: v isnt null
        backup: true
      @system.link
        source: spark.history.conf_dir
        target: '/usr/hdp/current/spark-historyserver/conf'

## Clients Configuration

      @hconfigure
        header: 'Hive Site'
        target: "#{spark.history.conf_dir}/hive-site.xml"
        source: "/etc/hive/conf/hive-site.xml"
        merge: true
        backup: true

      @hconfigure
        header: 'Core Site'
        target: "#{spark.history.conf_dir}/core-site.xml"
        source: "/etc/hadoop/conf/core-site.xml"
        merge: true
        backup: true

      @system.copy
        target: "#{spark.history.conf_dir}/hdfs-site.xml"
        source: "/etc/hadoop/conf/hdfs-site.xml"

## Kerberos

      @krb5.addprinc krb5,
        header: 'Kerberos'
        principal: spark.history.conf['spark.history.kerberos.principal']
        keytab: spark.history.conf['spark.history.kerberos.keytab']
        randkey: true
        uid: spark.user.name
        gid: spark.group.name

## Dependencies

    path = require 'path'
    quote = require 'regexp-quote'
    mkcmd = require '../../lib/mkcmd'
