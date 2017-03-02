
# Apache Spark SQL Thrift Server



    module.exports =  header: 'Spark SQL Thrift Server Install', handler: (options) ->
      {spark, realm, ssl} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
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
        name: 'spark-thriftserver'
      @service.init
        destination : "/etc/init.d/spark-thrift-server"
        source: "#{__dirname}/../resources/spark-thrift-server"
        local: true
        context: @config.ryba
        backup: true
        mode: 0o0755
      @system.tmpfs
        if: -> (options.store['mecano:system:type'] in ['redhat','centos']) and (options.store['mecano:system:release'][0] is '7')
        mount: spark.thrift.pid_dir
        uid: spark.user.name
        gid: @config.ryba.hadoop_group.gid
        perm: '0750'


## IPTables

| Service              | Port  | Proto | Info              |
|----------------------|-------|-------|-------------------|
| spark history server | 10015 | http  | Spark HTTP server |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: spark.thrift.hive_site['hive.server2.thrift.port'], protocol: 'tcp', state: 'NEW', comment: "Spark SQL Thrift Server (binary)" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: spark.thrift.hive_site['hive.server2.thrift.http.port'], protocol: 'tcp', state: 'NEW', comment: "Spark SQL Thrift Server (http)" }
        ]
        if: @config.iptables.action is 'start'

## Layout
Custom mode: 0o0760 to allow hive user to write into /var/run/spark and /var/log/spark

      @call header: 'Layout', handler: ->
        @system.mkdir
          target: spark.thrift.pid_dir
          uid: spark.user.name
          gid: @config.ryba.hadoop_group.gid
          mode: 0o0770
        @system.mkdir
          target: spark.thrift.log_dir
          uid: spark.user.name
          gid: @config.ryba.hadoop_group.gid
          mode: 0o0770
        @system.mkdir
          target: spark.thrift.conf_dir
          uid: spark.user.name
          gid: @config.ryba.hadoop_group.gid
        @system.remove
          target: '/usr/hdp/current/spark-thriftserver/conf'
        @system.link
          target: '/usr/hdp/current/spark-thriftserver/conf'
          source: spark.thrift.conf_dir

## HDFS Layout

      @hdfs_mkdir
        target: "/user/#{spark.thrift.user_name}"
        user: spark.thrift.user_name
        group: spark.thrift.user_name
        mode: 0o0775
        krb5_user: @config.ryba.hdfs.krb5_user

## Spark Conf

      @call header: 'Spark Configuration', handler: ->
        @file.render
          destination : "#{spark.thrift.conf_dir}/spark-env.sh"
          source: "#{__dirname}/../resources/spark-env.sh.j2"
          local: true
          context: @config
          backup: true
          uid: spark.user.name
          gid: @config.ryba.hadoop_group.gid
          mode: 0o0750
        @file.properties
          header: 'Spark Defaults'
          target: "#{spark.thrift.conf_dir}/spark-defaults.conf"
          content: spark.thrift.conf
          backup: true
          uid: spark.user.name
          gid: @config.ryba.hadoop_group.gid
          mode: 0o0750
          separator: ' '
        @file
          header: 'Spark env'
          destination : "#{spark.thrift.conf_dir}/spark-env.sh"
          # See "/usr/hdp/current/spark-historyserver/sbin/spark-daemon.sh" for
          # additionnal environmental variables.
          write: [
            match :/^export SPARK_PID_DIR=.*$/mg
            replace:"export SPARK_PID_DIR=#{spark.thrift.pid_dir} # RYBA CONF \"ryba.spark.pid_dir\", DONT OVEWRITE"
            append: true
          ,
            match :/^export SPARK_CONF_DIR=.*$/mg
            # replace:"export SPARK_CONF_DIR=#{spark.conf_dir} # RYBA CONF \"ryba.spark.conf_dir\", DONT OVERWRITE"
            replace:"export SPARK_CONF_DIR=${SPARK_HOME:-/usr/hdp/current/spark-thriftserver}/conf # RYBA CONF \"ryba.spark.conf_dir\", DONT OVERWRITE"
            append: true
          ,
            match :/^export SPARK_LOG_DIR=.*$/mg
            replace:"export SPARK_LOG_DIR=#{spark.thrift.log_dir} # RYBA CONF \"ryba.spark.log_dir\", DONT OVERWRITE"
            append: true
          ,
            match :/^export JAVA_HOME=.*$/mg
            replace:"export JAVA_HOME=#{java_home} # RYBA, DONT OVERWRITE"
            append: true
          ]

## Hive Client Conf

      @call header:'Hive Client Conf', handler: ->
        @system.copy
          target: "#{spark.thrift.conf_dir}/hive-site.xml"
          source: '/etc/hive/conf/hive-site.xml'

        @hconfigure
          target: "#{spark.thrift.conf_dir}/hive-site.xml"
          properties: spark.thrift.hive_site
          merge: true
          uid: spark.user.name
          gid: @config.ryba.hadoop_group.gid
          mode: 0o0750

## Spark SQL Thrift SSL Conf      

      @call
        header: 'SSL'
        if: -> spark.thrift.hive_site['hive.server2.use.SSL'] is 'true'
        handler: ->
          tmp_location = "/var/tmp/ryba/ssl"
          @file.download
            source: ssl.cacert
            target: "#{tmp_location}/#{path.basename ssl.cacert}"
            mode: 0o0600
            shy: true
          @file.download
            source: ssl.cert
            target: "#{tmp_location}/#{path.basename ssl.cert}"
            mode: 0o0600
            shy: true
          @file.download
            source: ssl.key
            target: "#{tmp_location}/#{path.basename ssl.key}"
            mode: 0o0600
            shy: true
          @java.keystore_add
            keystore: spark.thrift.hive_site['hive.server2.keystore.path']
            storepass: spark.thrift.hive_site['hive.server2.keystore.password']
            caname: "hive_root_ca"
            cacert: "#{tmp_location}/#{path.basename ssl.cacert}"
            key: "#{tmp_location}/#{path.basename ssl.key}"
            cert: "#{tmp_location}/#{path.basename ssl.cert}"
            keypass: spark.thrift.hive_site['hive.server2.keystore.password']
            name: @config.shortname
          # @java.keystore_add
          #   keystore: hive.site['hive.server2.keystore.path']
          #   storepass: hive.site['hive.server2.keystore.password']
          #   caname: "hadoop_root_ca"
          #   cacert: "#{tmp_location}/#{path.basename ssl.cacert}"
          @system.remove
            target: "#{tmp_location}/#{path.basename ssl.cacert}"
            shy: true
          @system.remove
            target: "#{tmp_location}/#{path.basename ssl.cert}"
            shy: true
          @system.remove
            target: "#{tmp_location}/#{path.basename ssl.key}"
            shy: true
          @service
            srv_name: 'spark-thrift-server'
            action: 'restart'
            if: -> @status()

## Log4j 

      @file.properties
        header: 'log4j Properties'
        target: "#{spark.thrift.conf_dir}/log4j.properties"
        content: spark.thrift.log4j
        backup: true

## Dependencies

    path = require 'path'
    quote = require 'regexp-quote'
    mkcmd = require '../../lib/mkcmd'
