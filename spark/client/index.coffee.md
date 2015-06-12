# Spark Client


    module.exports = []

## Spark Configuration

    module.exports.configure = (ctx) ->
      require('../../lib/base').configure ctx
      require('../../../ryba/hadoop/core').configure ctx
      require("../../../ryba/hive/hcatalog").configure ctx

      {core_site, hadoop_conf_dir} = ctx.config.ryba
      {ryba} = ctx.config
      spark = ctx.config.ryba.spark ?= {}
      spark.user ?= {}
      spark.user = name: spark.user if typeof spark.user is 'string'
      spark.user.name ?= 'spark'
      spark.user.system ?= true
      spark.user.comment ?= 'Spark User'
      # spark.user.home ?= '/var/run/spark'
      spark.user.groups ?= 'hadoop'
      # Group
      spark.group ?= {}
      spark.group = name: spark.group if typeof spark.group is 'string'
      spark.group.name ?= 'spark'
      spark.group.system ?= true
      spark.user.gid ?= spark.group.name
      spark.client_dir ?= '/usr/hdp/current/spark-client/'
      spark.conf_dir ?= '/usr/hdp/current/spark-client/conf'
      #not sure about the port of the webui from the configuration page these port and address is
      # the one of  yarn history server, but ambari and hortonworks does set these to a different
      #adresse and port let configuration as hortonworks documentation
      # SSL for HTTPS connection and RPC Encryption
      core_site['hadoop.ssl.require.client.cert'] ?= 'false'
      core_site['hadoop.ssl.hostname.verifier'] ?= 'DEFAULT'
      core_site['hadoop.ssl.keystores.factory.class'] ?= 'org.apache.hadoop.security.ssl.FileBasedKeyStoresFactory'
      core_site['hadoop.ssl.server.conf'] ?= 'ssl-server.xml'
      core_site['hadoop.ssl.client.conf'] ?= 'ssl-client.xml'
      spark.ssl = {}
      spark.ssl.fs = {}
      spark.ssl.fs['enabled'] = false
      spark.ssl.fs['spark.ssl.enabledAlgorithms'] ?= 'MD5'
      spark.ssl.fs['spark.ssl.keyPassword'] ?= 'ryba123'
      spark.ssl.fs['spark.ssl.keyStore'] ?= "#{spark.conf_dir}/keystore"
      spark.ssl.fs['spark.ssl.keyStorePassword'] ?= 'ryba123'
      spark.ssl.fs['spark.ssl.protocol'] ?= 'SSLv3'
      spark.ssl.fs['spark.ssl.trustStore'] ?= "#{spark.conf_dir}/trustore"
      spark.ssl.fs['spark.ssl.trustStorePassword'] ?= 'ryba123'



    #does set the check during install because requires too much power from the dev environment
    module.exports.push commands: 'install', modules: [
      'ryba/spark/client/install'
      #'ryba/spark/client/check'
    ]
    module.exports.push commands: 'check', modules: 'ryba/spark/client/check'
