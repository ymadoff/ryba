# Apache Spark Install Cluster Mode

[Spark Installation][Spark-install] following hortonworks guidelines to install
Spark requires HDFS and Yarn. Install spark in Yarn cluster mode.

Resources:

[Tips and Tricks from Altic Scale][https://www.altiscale.com/blog/tips-and-tricks-for-running-spark-on-hadoop-part-2-2/)   
  
    module.exports = header: 'Spark Client Install', handler: ->
      {ssl, ssl_server, ssl_client, spark, hadoop_group, hadoop_conf_dir, hive} = @config.ryba

## Spark Users And Group

By default, the "spark" package create the following entries:

```bash
cat /etc/passwd | grep spark
spark:x:495:494:Spark:/var/lib/spark:/bin/bash
cat /etc/group | grep spark
spark:x:494:
```

      @group spark.group
      @user spark.user

## Spark Service Installation

Install the spark and python packages.

      @service
        name: 'spark'
      @service
        name: 'spark-python'

## HFDS Layout
      
      
      @call header: 'HFDS Layout', timeout: -1, handler: ->
        status = user_owner = group_owner = null
        spark_yarn_jar = spark.conf['spark.yarn.jar']
        @execute
          cmd: mkcmd.hdfs @, """
            hdfs dfs -mkdir -p /apps/#{spark.user.name}
            hdfs dfs -chown -R #{spark.user.name}:#{spark.group.name} /apps/#{spark.user.name}
            hdfs dfs -chmod 755 /apps/#{spark.user.name}
            hdfs dfs -put -f /usr/hdp/current/spark-client/lib/spark-assembly-*.jar #{spark_yarn_jar}
            hdfs dfs -chown #{spark.user.name}:#{spark.group.name} #{spark_yarn_jar}
            hdfs dfs -chmod 644 #{spark_yarn_jar}
            """

## Spark Worker events log dir

      @call header: 'Logdir HDFS Permissions', handler: ->
        fs_log_dir = spark.conf['spark.eventLog.dir']
        @execute
          cmd: mkcmd.hdfs @, """
            hdfs dfs -mkdir -p /user/#{spark.user.name}
            hdfs dfs -mkdir -p #{fs_log_dir}
            hdfs dfs -chown -R #{spark.user.name}:#{spark.group.name} /user/#{spark.user.name}
            hdfs dfs -chmod -R 755 /user/#{spark.user.name}
            hdfs dfs -chmod 1777 #{fs_log_dir}
            """

## Spark SSL

Installs SSL certificates for spark. At the moment of this writing, Spark
supports SSL Only in akka mode and fs mode ( file sharing and date streaming).
The web ui does not support SSL.

SSL must be configured on each node and configured for each component involved
in communication using the particular protocol.

      @call
        header: 'JKS stores'
        retry: 0
        if: -> @config.ryba.spark.conf['spark.ssl.enabled'] is 'true'
        handler: ->
         tmp_location = "/tmp/ryba_hdp_ssl_#{Date.now()}"
         @download
            source: ssl.cacert
            destination: "#{tmp_location}_cacert"
            shy: true
         @download
            source: ssl.cert
            destination: "#{tmp_location}_cert"
            shy: true
         @download
            source: ssl.key
            destination: "#{tmp_location}_key"
            shy: true
         # Client: import certificate to all hosts
         @java_keystore_add
            keystore: spark.conf['spark.ssl.trustStore']
            storepass: spark.conf['spark.ssl.trustStorePassword']
            caname: "hadoop_spark_ca"
            cacert: "#{tmp_location}_cacert"
         # Server: import certificates, private and public keys to hosts with a server
         @java_keystore_add
            keystore: spark.conf['spark.ssl.trustStore']
            storepass: spark.conf['spark.ssl.trustStorePassword']
            caname: "hadoop_spark_ca"
            cacert: "#{tmp_location}_cacert"
            key: "#{tmp_location}_key"
            cert: "#{tmp_location}_cert"
            keypass: spark.conf['spark.ssl.keyPassword']
            name: @config.shortname
         @java_keystore_add
            keystore: spark.conf['spark.ssl.keyStore']
            storepass: spark.conf['spark.ssl.keyStorePassword']
            caname: "hadoop_spark_ca"
            cacert: "#{tmp_location}_cacert"
         @remove
            destination: "#{tmp_location}_cacert"
            shy: true
         @remove
            destination: "#{tmp_location}_cert"
            shy: true
         @remove
            destination: "#{tmp_location}_key"
            shy: true

## Spark Configuration files

Configure en environment file /etc/spark/conf/spark-env.sh and /etc/spark/conf/spark-defaults.conf
Set the version of the hadoop cluster to the latest one. Yarn cluster mode supports starting to 2.2.2-4
Set [Spark configuration][spark-conf] variables
The spark.logEvent.enabled property is set to true to enable the log to be available after the job
has finished (logs are only available in yarn-cluster mode). 

      @call header: 'Configure',  handler: ->
        hdp_current_version = null
        hadoop_conf_dir = '/usr/hdp/current/hadoop-client/conf'
        @execute
          cmd:  "hdp-select versions | tail -1"
        , (err, executed, stdout, stderr) ->
          return err if err
          hdp_current_version = stdout.trim() if executed
          spark.conf['spark.driver.extraJavaOptions'] ?= "-Dhdp.version=#{hdp_current_version}"
          spark.conf['spark.yarn.am.extraJavaOptions'] ?= "-Dhdp.version=#{hdp_current_version}"
        @call ->
          @write
            destination : "#{spark.conf_dir}/java-opts"
            content: "-Dhdp.version=#{hdp_current_version}"
          @hconfigure
            header: 'Hive Site'
            destination: "#{spark.conf_dir}/hive-site.xml"
            default: "/etc/hive/conf/hive-site.xml"
            properties: 'hive.execution.engine': 'mr'
            merge: true
            backup: true
          @render
            destination : "#{spark.conf_dir}/spark-env.sh"
            source: "#{__dirname}/../resources/spark-env.sh.j2"
            local_source: true
            context: @config
            backup: true
          @write_properties
            destination: "#{spark.conf_dir}/spark-defaults.conf"
            content: spark.conf
            merge: true
            separator: ' '
          @write
            destination: "#{spark.conf_dir}/metrics.properties"
            write: for k, v of spark.metrics
              match: ///^#{quote k}=.*$///mg
              replace: if v is null then "" else "#{k}=#{v}"
              append: v isnt null
            backup: true

## Dependencies

    mkcmd = require '../../lib/mkcmd'
    quote = require 'regexp-quote'
    string = require 'mecano/lib/misc/string'

[spark-conf]:https://spark.apache.org/docs/latest/configuration.html
