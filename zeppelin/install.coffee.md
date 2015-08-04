# Zeppelin install

Install Zeppelin with build dockerized image.
Configured for a YARN  cluster, running with spark 1.2.1.
Spark comes with 1.2.1 in HDP 2.2.4.

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/commons/docker'
    module.exports.push 'ryba/spark/client'
    module.exports.push 'ryba/hive/client'
    module.exports.push require '../lib/hconfigure'
    module.exports.push require('./index').configure


## IPTables

| Service                 | Port  | Proto | Parameter                |
|-------------------------|-------|-------|--------------------------|
| Zeppelin Server http    | 9090  | tcp   | env[ZEPPELIN_PORT]       |
| Zeppelin Server https   | 9099  | tcp   | env[ZEPPELIN_PORT]       |
| Zeppelin Websocket      | 9091  | tcp   | env[ZEPPELIN_PORT] +  1  |
| Zeppelin Websocket      | 10000 | tcp   | env[ZEPPELIN_PORT] +  1  |


IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).
It's the  host' port server map from the container

    module.exports.push name: 'Zeppelin Server # IPTables', handler: (ctx, next) ->
      {zeppelin} = ctx.config.ryba
      next null,null 
      # ctx.iptables
      #   rules: [
      #     { chain: 'INPUT', jump: 'ACCEPT', dport: zeppelin.env.ZEPPELIN_PORT, protocol: 'tcp', state: 'NEW', comment: "Zeppelin Server" }
      #   ]
      #   if: ctx.config.iptables.action is 'start'
      #.then next


## Zeppelin SSL

Installs SSL certificates for Zeppelin. Creates trustore et keystore
SSL only required for the server

    # module.exports.push name: 'Spark Client # JKS stores', retry: 0, handler: (ctx, next) ->
    #  {ssl, ssl_server, ssl_client, zeppelin} = ctx.config.ryba
    #  tmp_location = "/tmp/ryba_hdp_ssl_#{Date.now()}"
    #  modified = false
    #  ctx
    #  .upload
    #     source: ssl.cacert
    #     destination: "#{tmp_location}_cacert"
    #     shy: true
    #  .upload
    #     source: ssl.cert
    #     destination: "#{tmp_location}_cert"
    #     shy: true
    #  .upload
    #     source: ssl.key
    #     destination: "#{tmp_location}_key"
    #     shy: true
    #  # Client: import certificate to all hosts
    #  .java_keystore_add
    #     keystore: zeppelin.site['zeppelin.ssl.keystore.path']
    #     storepass: zeppelin.site['zeppelin.ssl.keystore.password']
    #     caname: "hadoop_zeppelin_ca"
    #     cacert: "#{tmp_location}_cacert"
    #  # Server: import certificates, private and public keys to hosts with a server
    #  .java_keystore_add
    #     keystore: zeppelin.site['zeppelin.ssl.truststore.path']
    #     storepass: zeppelin.site['zeppelin.ssl.truststore.password']
    #     caname: "hadoop_zeppelin_ca"
    #     cacert: "#{tmp_location}_cacert"
    #     key: "#{tmp_location}_key"
    #     cert: "#{tmp_location}_cert"
    #     keypass: spark.ssl.fs['spark.ssl.keyPassword']
    #     name: ctx.config.shortname
    #  .java_keystore_add
    #     keystore: spark.ssl.fs['spark.ssl.keyStore']
    #     storepass: spark.ssl.fs['spark.ssl.keyStorePassword']
    #     caname: "hadoop_spark_ca"
    #     cacert: "#{tmp_location}_cacert"
    #  .remove
    #     destination: "#{tmp_location}_cacert"
    #     shy: true
    #  .remove
    #     destination: "#{tmp_location}_cert"
    #     shy: true
    #  .remove
    #     destination: "#{tmp_location}_key"
    #     shy: true
    #  .then next

## GetHDP select status

    module.exports.push name: 'Zeppelin Environment # HDP',  handler: (ctx, next) ->
      {zeppelin} = ctx.config.ryba
      ctx
      .execute
          cmd:  "hdp-select versions | tail -1"
      , (err, executed, stdout, stderr) ->
          return next err if err
          hdp_select_version = stdout.trim() if executed
          zeppelin.env['ZEPPELIN_JAVA_OPTS'] ?= "-Dhdp.version=#{hdp_select_version}"
          next null


## Zeppelin properties configuration
    
    module.exports.push name: 'Zeppelin Environment # Configure',  handler: (ctx, next) ->
      {hadoop_group,hadoop_conf_dir, hdfs, zeppelin} = ctx.config.ryba
      ctx
      .mkdir
        destination: zeppelin.destination
        mode: 0o0750
      .download
        source: "#{__dirname}/../resources/zeppelin/zeppelin-site.xml"
        destination: "#{zeppelin.conf_dir}/zeppelin-site.xml"
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
        if_not_exists: "#{zeppelin.conf_dir}/zeppelin-site.xml"
      .download
        source: "#{__dirname}/../resources/zeppelin/zeppelin-env.sh"
        destination: "#{zeppelin.conf_dir}/zeppelin-env.sh"
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
        if_not_exists: "#{zeppelin.conf_dir}/zeppelin-env.sh"
      .hconfigure
        destination: "#{zeppelin.conf_dir}/zeppelin-site.xml"
        default: "#{__dirname}/../resources/zeppelin/zeppelin-site.xml"
        local_default: true
        properties: zeppelin.site
        merge: true
        backup: true
      .write
        destination: "#{zeppelin.conf_dir}/zeppelin-env.sh"
        write: for k, v of zeppelin.env
          match: RegExp "^export\\s+(#{quote k})(.*)$", 'm'
          replace: "export #{k}=#{v}"
          append: true
        backup: true
        eof: true
      .then next

## Install Zeppelin docker image

 Load Zeppelin docker image from local host

    module.exports.push name: 'Zeppelin Image # Import', timeout: -1, handler: (ctx, next) ->
      {zeppelin} = ctx.config.ryba
      ctx
      .download
        source: "#{zeppelin.build.directory}/zeppelin.tar"
        destination: "#{zeppelin.build.directory}/zeppelin.tar"
        if_not_exists: "#{zeppelin.build.directory}/zeppelin.tar"
      .docker_load
        machine: 'ryba'
        source: "#{zeppelin.build.directory}/zeppelin.tar"
        
      .then next  


## Runs Zeppelin container 

    module.exports.push name: 'Zeppelin Container # Run',  handler: (ctx, next) ->
      {hadoop_group,hadoop_conf_dir, hdfs, zeppelin} = ctx.config.ryba
      websocket = parseInt(zeppelin.site['zeppelin.server.port'])+1
      ctx
      .docker_run
        image: 'ryba/zeppelin:0.6'
        volume: [
                "#{hadoop_conf_dir}:#{hadoop_conf_dir}"
                "#{zeppelin.conf_dir}:#{zeppelin.conf_dir}"
                '/etc/krb5.conf:/etc/krb5.conf'
                '/etc/security/keytabs:/etc/security/keytabs'
                '/etc/usr/hdp:/usr/hdp'
                '/etc/spark/conf:/etc/spark/conf'
                ]
        net: 'host'
        name: 'zeppelin_notebook'
        hostname: 'zeppelin_notebook.ryba'
        #not_if_exec: 'docker inspect zeppelin_notebook'
      .then next

## Dependencies

    quote = require 'regexp-quote'
