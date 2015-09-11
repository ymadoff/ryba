# Apache Spark Install Cluster Mode

[Spark Installation][Spark-install] following hortonworks guidelines to install
Spark requires HDFS and Yarn. Install spark in Yarn cluster mode.

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hive/client'
    # module.exports.push require('./index').configure
    module.exports.push require '../../lib/hdp_select'
    module.exports.push require '../../lib/hconfigure'
    module.exports.push 'ryba/spark/default'


## Spark Users And Group

By default, the "spark" package create the following entries:

```bash
cat /etc/passwd | grep spark
spark:x:495:494:Spark:/var/lib/spark:/bin/bash
cat /etc/group | grep spark
spark:x:494:
```

    module.exports.push name: 'Spark HS # Users & Groups', handler: ->
      {spark} = @config.ryba
      @group spark.group
      @user spark.user

## Spark Service Installation

Install the spark and python packages.

    module.exports.push name: 'Spark Client # Service', handler: ->
      @service
        name: 'spark'
      @service
        name: 'spark-python'

## Spark SSL

Installs SSL certificates for spark. At the moment of this writing, Spark
supports SSL Only in akka mode and fs mode ( file sharing and date streaming).
The web ui does not support SSL.

SSL must be configured on each node and configured for each component involved
in communication using the particular protocol.

    module.exports.push
      name: 'Spark Client # JKS stores'
      retry: 0
      if: -> @config.ryba.spark.conf['spark.ssl.enabled'] is 'true'
      handler: ->
       {ssl, ssl_server, ssl_client, spark} = @config.ryba
       tmp_location = "/tmp/ryba_hdp_ssl_#{Date.now()}"
       @upload
          source: ssl.cacert
          destination: "#{tmp_location}_cacert"
          shy: true
       @upload
          source: ssl.cert
          destination: "#{tmp_location}_cert"
          shy: true
       @upload
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

    module.exports.push name: 'Spark Client # Configure',  handler: ->
      {java_home} = @config.java
      {ryba} = @config
      {spark, hadoop_group, hadoop_conf_dir, hive} = ryba
      hdp_select_version = null
      @execute
        cmd:  "hdp-select versions | tail -1"
      , (err, executed, stdout, stderr) ->
        return next err if err
        hdp_select_version = stdout.trim() if executed
        spark.conf['spark.driver.extraJavaOptions'] ?= "-Dhdp.version=#{hdp_select_version}"
        spark.conf['spark.yarn.am.extraJavaOptions'] ?= "-Dhdp.version=#{hdp_select_version}"
      @call ->
        @write
          destination : "#{spark.conf_dir}/java-opts"
          content: "-Dhdp.version=#{hdp_select_version}"
        @hconfigure
          destination: "#{spark.conf_dir}/hive-site.xml"
          properties: hive.site
        @write
          destination : "#{spark.conf_dir}/spark-env.sh"
          write: [
            match :/^export HADOOP_CONF_DIR=.*$/mg
            replace:"export HADOOP_CONF_DIR=#{hadoop_conf_dir}"
          ,
            replace: """
            if [ -d "/etc/tez/conf/" ]; then
            export TEZ_CONF_DIR=/etc/tez/conf
            else
            export TEZ_CONF_DIR=
            fi
            """
            from: '# RYBA TEZ START'
            to: '# RYBA TEZ END'
            append: true
          ,
            match :/^export SPARK_CONF_DIR=.*$/mg
            # replace:"export SPARK_CONF_DIR=#{spark.conf_dir} # RYBA CONF \"ryba.spark.conf_dir\", DONT OVERWRITE"
            replace:"export SPARK_CONF_DIR=${SPARK_HOME:-/usr/hdp/current/spark-historyserver}/conf # RYBA CONF \"ryba.spark.conf_dir\", DONT OVERWRITE"
            append: true
          ,
            match :/^export JAVA_HOME=.*$/mg
            replace:"export JAVA_HOME=#{java_home} # RYBA, DONT OVERWRITE"
            append: true
          ]
        @write
          destination: "#{spark.conf_dir}/spark-defaults.conf"
          write: for k, v of spark.conf
            match: ///^#{quote k}\ .*$///mg # Seems like space are discarded
            # match: new RegExp "^#{quote k} .*$", 'mg'
            replace: if v is null then "" else "#{k} #{v}"
            append: v isnt null
          backup: true
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

[spark-conf]:https://spark.apache.org/docs/latest/configuration.html
