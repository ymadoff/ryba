# Apache Spark Install Cluster Mode

[Spark Installation][Spark-install] following hortonworks guidelines to install Spark
Requires HDFS and Yarn. Install spark in Yarn cluster mode
  

    fs = require 'fs'
    quote = require 'regexp-quote'

    
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure
    module.exports.push require '../../lib/hdp_select'

    

## Spark Service Installation

    module.exports.push name: 'Spark # Service', handler: (ctx, next) ->  
      ctx.service
        name: 'spark'
      , next

## Spark Python Installation

    module.exports.push name: 'Spark # Python', handler: (ctx, next) ->  
      ctx.service
        name: 'spark-python'
      , next

## Spark Users And Group

    module.exports.push name: 'Spark  # Users & Groups', handler: (ctx, next) ->
      {spark, hadoop_group} = ctx.config.ryba
      ctx.execute
        cmd: "useradd #{spark.user.name} -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Apache Spark Client\""
        code: 0
        code_skipped: 9
      , next

## Spark SSL
Installs SSL certificates for spark. At the moment of writing this lines, Spark supports SSL
Only in akka mode and fs mode ( file sharing and date streaming). The web ui does not support SSL

    module.exports.push name: 'Spark SSL # JKS stores', retry: 0, handler: (ctx, next) ->
     {ssl, ssl_server, ssl_client, spark} = ctx.config.ryba
     tmp_location = "/tmp/ryba_hdp_ssl_#{Date.now()}"
     modified = false
     has_modules = ctx.has_any_modules [
       'ryba/spark/history_server'
     ]
     ctx
     .upload
        source: ssl.cacert
        destination: "#{tmp_location}_cacert"
        shy: true
     .upload
        source: ssl.cert
        destination: "#{tmp_location}_cert"
        shy: true
     .upload
        source: ssl.key
        destination: "#{tmp_location}_key"
        shy: true
     # Client: import certificate to all hosts
     .java_keystore_add
        keystore: spark.ssl.fs['spark.ssl.trustStore']
        storepass: spark.ssl.fs['spark.ssl.trustStorePassword']
        caname: "hadoop_spark_ca"
        cacert: "#{tmp_location}_cacert"
     # Server: import certificates, private and public keys to hosts with a server
     .java_keystore_add
        keystore: spark.ssl.fs['spark.ssl.trustStore']
        storepass: spark.ssl.fs['spark.ssl.trustStorePassword']
        caname: "hadoop_spark_ca"
        cacert: "#{tmp_location}_cacert"
        key: "#{tmp_location}_key"
        cert: "#{tmp_location}_cert"
        keypass: spark.ssl.fs['spark.ssl.keyPassword']
        name: ctx.config.shortname
     .java_keystore_add
        keystore: spark.ssl.fs['spark.ssl.keyStore']
        storepass: spark.ssl.fs['spark.ssl.keyStorePassword']
        caname: "hadoop_spark_ca"
        cacert: "#{tmp_location}_cacert"
     .remove
        destination: "#{tmp_location}_cacert"
        shy: true
     .remove
        destination: "#{tmp_location}_cert"
        shy: true
     .remove
        destination: "#{tmp_location}_key"
        shy: true
     .then (err, status) ->
        return next err if err
        modified = true if status
        next(err, modified)



## Spark Configuration files
Configure en environment file /etc/spark/conf/spark-env.sh and /etc/spark/conf/spark-defaults.conf
Set the version of the hadoop cluster to the latest one. Yarn cluster mode supports starting to 2.2.2-4
Set [Spark configuration][spark-conf] variables

    module.exports.push name: 'Spark # Configure',  handler: (ctx, next) ->
      {ryba} = ctx.config
      {spark, hadoop_group,hadoop_conf_dir, hive} = ryba
      hdp_select_version = "latest"
      do_get_hdp_version = ->
        ctx
          .child().execute
                cmd:  """
                      hdp-select versions | tail -1
                      """
        , (err, executed, stdout, stderr) ->
          return err if err
          hdp_select_version = stdout.trim() if executed
          do_java_opts()
      do_java_opts = ->
        ctx.write 
          destination : "#{spark.conf_dir}/java-opts"
          content: "-Dhdp.version=#{hdp_select_version}"
        , (err, executed) ->
          return err if err
          do_hive_site()
      do_hive_site = ->
        ctx.hconfigure
          destination: "#{spark.conf_dir}/hive-site.xml"
          properties: hive.site
          backup: true
        #ctx.write
          #destination : "#{spark.conf_dir}/hive-site.xml"  
          #content : "#{hive['hive.metastore.uris']}"
          #eof : true
        , (err, executed) ->
          return err if err
          do_spark_env_download()
      do_spark_env_download = ->
        ctx.download
          destination: "#{spark.conf_dir}/spark-env.sh"
          source: "#{__dirname}/../../resources/spark/spark-env.sh"
          uid: spark.user.name
          gid: hadoop_group.name
          mode: 0o755
          backup: true
        , (err, uploaded) ->
          return  err if err
          do_spark_env_write()
      do_spark_env_write = ->
        ctx.write
          destination : "#{spark.conf_dir}/spark-env.sh"
          write: [
             match :/^set HADOOP_CONF_DIR=.*$/mg
            replace:"set HADOOP_CONF_DIR=#{hadoop_conf_dir}"
          ]
          backup: true
        , (err, executed) ->
          return err if err
          do_spark_defaults_download()
      do_spark_defaults_download = ->
        ctx.download
          destination: "#{spark.conf_dir}/spark-defaults.conf"
          source: "#{__dirname}/../../resources/spark/spark-defaults.conf"
          uid: spark.user.name
          gid: hadoop_group.name
          mode: 0o755
          backup: true
        , (err, uploaded) ->
          return  err if err
          do_spark_defaults()
      do_spark_defaults = -> 
        ctx.write
          destination: "#{spark.conf_dir}/spark-defaults.conf"
          write: [
            match: /^spark\.driver\.extraJavaOptions*$/mg
            replace: "spark.driver.extraJavaOptions -Dhdp.version=#{hdp_select_version}"# Modified by RYBA Spark Client Install
            append: true
          ,
            match: /^spark\.yarn\.services.*$/mg
            replace: "spark.yarn.services org.apache.spark.deploy.yarn.history.YarnHistoryService"# Modified by RYBA Spark Client Install
            append: true
          ,
            match: /^spark\.history\.provider.*$/mg
            replace: "spark.history.provider org.apache.spark.deploy.yarn.history.YarnHistoryProvider"# Modified by RYBA Spark Client Install
            append: true
          ,
            match: /^spark\.yarn\.am\.extraJavaOptions.*$/mg
            replace: "spark.yarn.am.extraJavaOptions -Dhdp.version=#{hdp_select_version}"# Modified by RYBA Spark Client Install
            append: true
          ]
          backup: true
          , (err, executed) ->
            return err if err
            do_spark_defaults_ssl()
      do_spark_defaults_ssl = -> 
        fs = spark.ssl.fs
        if spark.ssl.fs['enabled'] is true
          ctx.write
            destination: "#{spark.conf_dir}/spark-defaults.conf"
            write: [
              match: /^spark\.ssl\.enabled.*$/m
              replace: "spark.ssl.enabled #{fs['enabled']}"# Modified by RYBA Spark History Server Install
              append:true
            ,
              match: /^spark\.ssl\.enabledAlgorithms.*$/m
              replace: "spark.ssl.enabledAlgorithms #{fs['spark.ssl.enabledAlgorithms']}"# Modified by RYBA Spark History Server Install
              append:true
            ,
              match: /^spark\.ssl\.keyPassword.*$/m
              replace: "spark.ssl.keyPassword #{fs['spark.ssl.keyPassword']}"# Modified by RYBA Spark History Server Install
              append:true
            ,
              match: /^spark\.ssl\.keyStore.*$/m
              replace: "spark.ssl.keyStore #{fs['spark.ssl.keyStore']}"# Modified by RYBA Spark History Server Install
              append:true
            ,
              match: /^spark\.ssl\.keyStorePassword.*$/m
              replace: "spark.ssl.keyStorePassword #{fs['spark.ssl.keyStorePassword']}"# Modified by RYBA Spark History Server Install
              append:true
            ,
              match: /^spark\.ssl\.truststore.*$/m
              replace: "spark.ssl.truststore #{fs['spark.ssl.trustStore']}"# Modified by RYBA Spark History Server Install
              append:true
            ,
              match: /^spark\.ssl\.trustStorePassword.*$/m
              replace: "spark.ssl.trustStorePassword #{fs['spark.ssl.trustStorePassword']}"# Modified by RYBA Spark History Server Install
              append:true
            , 
              match: /^spark\.ssl\.protocol.*$/m
              replace: "spark.ssl.protocol #{fs['spark.ssl.protocol']}"# Modified by RYBA Spark History Server Install
              append:true
            ]
            backup: true
          , (err, executed) ->
            return err if err
            next err, true
        else
          next()
      do_get_hdp_version()


## Spark History Server Configure

We set by default the address and port of the spark web ui server
The web ui can not be started with SSL enabled

    module.exports.push name: 'Spark Client HS # Configure',  handler: (ctx, next) ->
      require("../history_server/index").configure ctx
      {spark} = ctx.config.ryba  
      ctx.write
        destination: "#{spark.conf_dir}/spark-defaults.conf"
        write: [
          match: /^spark\.yarn\.historyServer\.address.*$/m
          replace: "spark.yarn.historyServer.address #{spark.history_server.fqdn}\:#{spark.history_server.port}" 
          append: true
        ,
          match: /^spark\.history\.ui\.port.*$/mg
          replace: "spark.history.ui.port #{spark.history_server.port}"
          append: true
        
        #thos properties enables the user to see the log after the job has finished 
        #,
            #match: /^spark\.eventLog\.enabled.*$/m
            #replace: "spark.eventLog.enabled true"
            #append:true
          #,
          #match: /^spark\.eventLog\.dir.*$/m
          #replace: "spark.eventLog.dir hdfs:///tmp/spark-events"
          #append:true          
        ]
        
        backup: true
      , (err, executed) ->
        next err, true


## Spark Files Permissions

    module.exports.push name: 'Spark  # Permissions', handler: (ctx, next) ->
      {spark} = ctx.config.ryba
      ctx.execute
        cmd: mkcmd.hdfs ctx, """
          hdfs dfs -mkdir -p /user/spark
          hdfs dfs -chown #{spark.user.name}:#{spark.user.name}  /user/spark
          hdfs dfs -chmod -R 755 /user/spark
          """
      , next


    mkcmd = require '../../lib/mkcmd'
    
[spark-conf]:https://spark.apache.org/docs/latest/configuration.html
    

