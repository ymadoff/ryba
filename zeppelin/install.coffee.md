
# Zeppelin Install

Install Zeppelin with build dockerized image.
Configured for a YARN  cluster, running with spark 1.2.1.
Spark comes with 1.2.1 in HDP 2.2.4.

    module.exports = header: 'Zeppelin Install', handler: ->
      {zeppelin, core_site, spark} = @config.ryba
      {hadoop_group, hadoop_conf_dir, hdfs} = @config.ryba

## Register

      @register 'hconfigure', 'ryba/lib/hconfigure'

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

      # @iptables
      #   header: 'IPTables'
      #   rules: [
      #     { chain: 'INPUT', jump: 'ACCEPT', dport: zeppelin.env.ZEPPELIN_PORT, protocol: 'tcp', state: 'NEW', comment: "Zeppelin Server" }
      #   ]
      #   if: @config.iptables.action is 'start'

## Zeppelin SSL

Installs SSL certificates for Zeppelin. Creates trustore et keystore
SSL only required for the server

    # module.exports.push header: 'Zeppelin Server # JKS stores', handler: ->
    #  {ssl, ssl_server, ssl_client, zeppelin} = @config.ryba
    #  tmp_location = "/tmp/ryba_hdp_ssl_#{Date.now()}"
    #  modified = false
    #  @download
    #     source: ssl.cacert
    #     target: "#{tmp_location}_cacert"
    #     shy: true
    #  @download
    #     source: ssl.cert
    #     target: "#{tmp_location}_cert"
    #     shy: true
    #  @download
    #     source: ssl.key
    #     target: "#{tmp_location}_key"
    #     shy: true
    #  # Client: import certificate to all hosts
    #  @java_keystore_add
    #     keystore: zeppelin.site['zeppelin.ssl.keystore.path']
    #     storepass: zeppelin.site['zeppelin.ssl.keystore.password']
    #     caname: "hadoop_zeppelin_ca"
    #     cacert: "#{tmp_location}_cacert"
    #  # Server: import certificates, private and public keys to hosts with a server
    #  @java_keystore_add
    #     keystore: zeppelin.site['zeppelin.ssl.truststore.path']
    #     storepass: zeppelin.site['zeppelin.ssl.truststore.password']
    #     caname: "hadoop_zeppelin_ca"
    #     cacert: "#{tmp_location}_cacert"
    #     key: "#{tmp_location}_key"
    #     cert: "#{tmp_location}_cert"
    #     keypass: spark.ssl.fs['spark.ssl.keyPassword']
    #     name: ctx.config.shortname
    #  @java_keystore_add
    #     keystore: spark.ssl.fs['spark.ssl.keyStore']
    #     storepass: spark.ssl.fs['spark.ssl.keyStorePassword']
    #     caname: "hadoop_spark_ca"
    #     cacert: "#{tmp_location}_cacert"
    #  @remove
    #     target: "#{tmp_location}_cacert"
    #     shy: true
    #  @remove
    #     target: "#{tmp_location}_cert"
    #     shy: true
    #  @remove
    #     target: "#{tmp_location}_key"
    #     shy: true

## HDP select status

      @execute
        header: 'Zeppelin Install # HDP Version'
        cmd:  "hdp-select versions | tail -1"
      , (err, executed, stdout, stderr) ->
        throw err if err
        hdp_select_version = stdout.trim() if executed
        zeppelin.env['ZEPPELIN_JAVA_OPTS'] ?= "-Dhdp.version=#{hdp_select_version}"

## Zeppelin spark assemblye Jar

Use the spark yarn assembly jar to execute spark aplication in yarn-client mode.

      @execute
        header: 'Zeppelin Install # Spark'
        cmd: 'ls -l /usr/hdp/current/spark-client/lib/ | grep -m 1 assembly | awk {\'print $9\'}'
      , (err, _, stdout) ->
        throw err if err
        spark_jar = stdout.trim()
        zeppelin.env['SPARK_YARN_JAR'] ?= "#{core_site['fs.defaultFS']}/user/#{spark.user.name}/share/lib/#{spark_jar}"

## Zeppelin properties configuration

      @mkdir
        header: 'Directory'
        target: "#{zeppelin.conf_dir}"
        mode: 0o0750
      @hconfigure
        header: 'Configuration'
        target: "#{zeppelin.conf_dir}/zeppelin-site.xml"
        default: "#{__dirname}/resources/zeppelin-site.xml"
        local_default: true
        properties: zeppelin.site
        merge: true
        backup: true

TODO: remove download and write and replace it with a template

      @download
        header: 'Download Environment'
        target: "#{zeppelin.conf_dir}/zeppelin-env.sh"
        source: "#{__dirname}/resources/zeppelin-env.sh"
        uid: hdfs.user.name
        gid: hadoop_group.name
        mode: 0o755
        unless_exists: true
      @file
        header: 'Update Environment'
        target: "#{zeppelin.conf_dir}/zeppelin-env.sh"
        write: for k, v of zeppelin.env
          match: RegExp "^export\\s+(#{quote k})(.*)$", 'm'
          replace: "export #{k}=#{v}"
          append: true
        backup: true
        eof: true

## Install Zeppelin docker image

Load Zeppelin docker image from local host

      @call header: 'Import', timeout: -1, handler: ->
        @download
          source: "#{@config.mecano.cache_dir}/zeppelin.tar"
          target: "/tmp/zeppelin.tar" # add versioning
        @docker_load
          machine: 'ryba'
          source: "/tmp/zeppelin.tar"

## Runs Zeppelin container 

      websocket = parseInt(zeppelin.site['zeppelin.server.port'])+1
      @docker_run
        header: 'Run'
        image: "#{zeppelin.prod.tag}"
        volume: [
          "#{hadoop_conf_dir}:#{hadoop_conf_dir}"
          "#{zeppelin.conf_dir}:/usr/lib/zeppelin/conf"
          '/etc/krb5.conf:/etc/krb5.conf'
          '/etc/security/keytabs:/etc/security/keytabs'
          '/usr/bin/hdfs:/usr/bin/hdfs'
          '/usr/bin/yarn:/usr/bin/yarn'
          '/usr/hdp:/usr/hdp'
          '/etc/spark/conf:/etc/spark/conf'
          '/etc/hive/conf:/etc/hive/conf'
          "#{zeppelin.log_dir}:/usr/lib/zeppelin/logs"
        ]
        net: 'host'
        name: 'zeppelin_notebook'
        # hostname: 'zeppelin_notebook.ryba'

## Dependencies

    quote = require 'regexp-quote'
