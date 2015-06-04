# Spark Client 

      
    module.exports = []

## Spark Configuration

    module.exports.configure = (ctx) ->
      require('../../lib/base').configure ctx
      require('../../../ryba/hadoop/core').configure ctx
      require("../../../ryba/hive/hcatalog").configure ctx
      {ryba} = ctx.config
      spark = ryba.spark ?= {}
      spark.user = {}
      spark.user.name = "spark"
      spark.client_dir = "/usr/hdp/current/spark-client/"
      spark.conf_dir = "/usr/hdp/current/spark-client/conf"
      history_server = spark.history_server ?= {}
      hs = ctx.hosts_with_module "ryba/spark/history_server"
      throw new Error("Spark History UI can only set to oon one host") if hs.lenght>1
      #history_server.fqdn = "#{hs[0]}"
      history_server.fqdn = "master2.ryba"
      history_server.port = "8190"
      spark.ui ="18080"
      history_server.isKerberos = "true"
      # require('./yarn').configure ctx
      {core_site, hadoop_conf_dir} = ctx.config.ryba
      ctx.config.ryba.ssl ?= {}
      ssl_client = ctx.config.ryba.ssl_client ?= {}
      ssl_server = ctx.config.ryba.ssl_server ?= {}
      # SSL for HTTPS connection and RPC Encryption
      core_site['hadoop.ssl.require.client.cert'] ?= 'false'
      core_site['hadoop.ssl.hostname.verifier'] ?= 'DEFAULT'
      core_site['hadoop.ssl.keystores.factory.class'] ?= 'org.apache.hadoop.security.ssl.FileBasedKeyStoresFactory'
      core_site['hadoop.ssl.server.conf'] ?= 'ssl-server.xml'
      core_site['hadoop.ssl.client.conf'] ?= 'ssl-client.xml'
      spark.ssl = {}
      spark.ssl.fs = {}
      spark.ssl.fs['enabled'] = false
      spark.ssl.fs['spark.ssl.enabledAlgorithms'] ?= "MD5"
      spark.ssl.fs['spark.ssl.keyPassword'] ?= "ryba123"
      spark.ssl.fs['spark.ssl.keyStore'] ?= "#{spark.conf_dir}/keystore"
      spark.ssl.fs['spark.ssl.keyStorePassword'] ?= "ryba123"
      spark.ssl.fs['spark.ssl.protocol'] ?= "SSLv3"
      spark.ssl.fs['spark.ssl.trustStore'] ?= "#{spark.conf_dir}/trustore"
      spark.ssl.fs['spark.ssl.trustStorePassword'] ?= "ryba123"


      
      
    module.exports.push commands: 'install', modules: [
      'ryba/spark/client/install'
      #'ryba/spark/client/check'
    ]
    module.exports.push commands: 'check', modules: 'ryba/spark/client/check'
