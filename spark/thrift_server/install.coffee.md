
# Apache Spark SQL Thrift Server



    module.exports =  header: 'Spark SQL Thrift Server Install', handler: ->
      {spark, realm, ssl} = @config.ryba
      {kadmin_principal, kadmin_password, admin_server} = @config.krb5.etc_krb5_conf.realms[realm]
      {java_home} = @config.java

      @register 'hdp_select', 'ryba/lib/hdp_select'
      @register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'
      @register 'hconfigure', 'ryba/lib/hconfigure'
      
# Users and Groups   

      @group spark.group
      @user spark.user

# Packages
      
      @service
        name: 'spark'
      @hdp_select
        name: 'spark-thriftserver'
      @render
        destination : "/etc/init.d/spark-thrift-server"
        source: "#{__dirname}/../resources/spark-thrift-server"
        local_source: true
        context: @config.ryba
        backup: true
        mode: 0o0755
      
          
## IPTables

| Service              | Port  | Proto | Info              |
|----------------------|-------|-------|-------------------|
| spark history server | 10015 | http  | Spark HTTP server |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: spark.thrift.hive_site['hive.server2.thrift.port'], protocol: 'tcp', state: 'NEW', comment: "Spark SQL Thrift Server (binary)" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: spark.thrift.hive_site['hive.server2.thrift.http.port'], protocol: 'tcp', state: 'NEW', comment: "Spark SQL Thrift Server (http)" }
        ]
        if: @config.iptables.action is 'start'

## Layout
Custom mode: 0o0760 to allow hive user to write into /var/run/spark and /var/log/spark

      @call header: 'Layout', handler: ->
        @mkdir
          destination: spark.thrift.pid_dir
          uid: spark.user.name
          gid: @config.ryba.hadoop_group.gid
          mode: 0o0770
        @mkdir
          destination: spark.thrift.log_dir
          uid: spark.user.name
          gid: @config.ryba.hadoop_group.gid
          mode: 0o0770
        @mkdir
          destination: spark.thrift.conf_dir
          uid: spark.user.name
          gid: @config.ryba.hadoop_group.gid
        @remove
          destination: '/usr/hdp/current/spark-thriftserver/conf'
        @link
          destination: '/usr/hdp/current/spark-thriftserver/conf'
          source: spark.thrift.conf_dir

## HDFS Layout
      
      @hdfs_mkdir
        destination: "/user/#{spark.thrift.user_name}"
        user: spark.thrift.user_name
        group: spark.thrift.user_name
        mode: 0o0775
        krb5_user: @config.ryba.hdfs.krb5_user

## Spark Conf
      
      @call header: 'Spark Configuration', handler: ->
        @render
          destination : "#{spark.thrift.conf_dir}/spark-env.sh"
          source: "#{__dirname}/../resources/spark-env.sh.j2"
          local_source: true
          context: @config
          backup: true
          uid: spark.user.name
          gid: @config.ryba.hadoop_group.gid
          mode: 0o0750
        @write_properties
          header: 'Spark Defaults'
          destination: "#{spark.thrift.conf_dir}/spark-defaults.conf"
          content: spark.thrift.conf
          backup: true
          uid: spark.user.name
          gid: @config.ryba.hadoop_group.gid
          mode: 0o0750
          separator: ' '
        @write
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
        @copy
          destination: "#{spark.thrift.conf_dir}/hive-site.xml"
          source: '/etc/hive/conf/hive-site.xml'
        
        @hconfigure
          destination: "#{spark.thrift.conf_dir}/hive-site.xml"
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
          @download
            source: ssl.cacert
            destination: "#{tmp_location}/#{path.basename ssl.cacert}"
            mode: 0o0600
            shy: true
          @download
            source: ssl.cert
            destination: "#{tmp_location}/#{path.basename ssl.cert}"
            mode: 0o0600
            shy: true
          @download
            source: ssl.key
            destination: "#{tmp_location}/#{path.basename ssl.key}"
            mode: 0o0600
            shy: true
          @java_keystore_add
            keystore: spark.thrift.hive_site['hive.server2.keystore.path']
            storepass: spark.thrift.hive_site['hive.server2.keystore.password']
            caname: "hive_root_ca"
            cacert: "#{tmp_location}/#{path.basename ssl.cacert}"
            key: "#{tmp_location}/#{path.basename ssl.key}"
            cert: "#{tmp_location}/#{path.basename ssl.cert}"
            keypass: spark.thrift.hive_site['hive.server2.keystore.password']
            name: @config.shortname
          # @java_keystore_add
          #   keystore: hive.site['hive.server2.keystore.path']
          #   storepass: hive.site['hive.server2.keystore.password']
          #   caname: "hadoop_root_ca"
          #   cacert: "#{tmp_location}/#{path.basename ssl.cacert}"
          @remove
            destination: "#{tmp_location}/#{path.basename ssl.cacert}"
            shy: true
          @remove
            destination: "#{tmp_location}/#{path.basename ssl.cert}"
            shy: true
          @remove
            destination: "#{tmp_location}/#{path.basename ssl.key}"
            shy: true
          @service
            srv_name: 'spark-thrift-server'
            action: 'restart'
            if: -> @status()

## Log4j 

      @write_properties
        header: 'log4j Properties'
        destination: "#{spark.thrift.conf_dir}/log4j.properties"
        content: spark.thrift.log4j
        backup: true

## Dependencies

    path = require 'path'
    quote = require 'regexp-quote'
    mkcmd = require '../../lib/mkcmd'
