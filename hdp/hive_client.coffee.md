---
title: 
layout: module
---

# Hive Client

    path = require 'path'
    mkcmd = require './lib/mkcmd'
    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'phyla/bootstrap'
    module.exports.push 'phyla/bootstrap/utils'
    module.exports.push 'phyla/hdp/hive_'
    module.exports.push 'phyla/hdp/mapred_client'
    module.exports.push 'phyla/hdp/yarn_client'

Example of a minimal client configuration:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <property>
    <name>hive.metastore.kerberos.keytab.file</name>
    <value>/etc/security/keytabs/hive.service.keytab</value>
  </property>
  <property>
    <name>hive.metastore.kerberos.principal</name>
    <value>hive/_HOST@ADALTAS.COM</value>
  </property>
  <property>
    <name>hive.metastore.sasl.enabled</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.metastore.uris</name>
    <value>thrift://big3.big:9083</value>
  </property>
</configuration>
```

    module.exports.push module.exports.configure = (ctx) ->
      require('./hdfs').configure ctx
      require('./hive_').configure ctx

## Configure

See [Hive/HCatalog Configuration Files](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.2/bk_installing_manually_book/content/rpm-chap6-3.html)

    module.exports.push name: 'HDP Hive & HCat client # Configure', callback: (ctx, next) ->
      {hive_site, hive_user, hadoop_group, hive_conf_dir} = ctx.config.hdp
      ctx.hconfigure
        destination: "#{hive_conf_dir}/hive-site.xml"
        default: "#{__dirname}/files/hive/hive-site.xml"
        local_default: true
        properties: hive_site
        merge: true
      , (err, configured) ->
        return next err if err
        ctx.execute
          cmd: """
          chown -R #{hive_user}:#{hadoop_group} #{hive_conf_dir}
          chmod -R 755 #{hive_conf_dir}
          """
        , (err) ->
          next err, if configured then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Hive & HCat client # Check Metastore', timeout: -1, callback: (ctx, next) ->
      {hive_metastore_host, hive_metastore_port} = ctx.config.hdp
      ctx.waitIsOpen hive_metastore_host, hive_metastore_port, (err) ->
        host = ctx.config.host.split('.')[0]
        ctx.execute
          cmd: mkcmd.test ctx, """
          if hdfs dfs -test -d /user/test/hive_#{ctx.config.host}/check_metastore_tb; then exit 2; fi
          hdfs dfs -mkdir -p /user/test/hive_#{ctx.config.host}/check_metastore_tb
          echo -e 'a|1\\\\nb|2\\\\nc|3' | hdfs dfs -put - /user/test/hive_#{ctx.config.host}/check_metastore_tb/data
          hive -e "
            CREATE DATABASE IF NOT EXISTS check_#{host}_db  LOCATION '/user/test/hive_#{ctx.config.host}'; \\
            USE check_#{host}_db; \\
            CREATE TABLE IF NOT EXISTS check_metastore_tb(col1 STRING, col2 INT); \\
          "
          hive -e "SELECT SUM(col2) FROM check_#{host}_db.check_metastore_tb;"
          hive -e "DROP TABLE check_#{host}_db.check_metastore_tb; DROP DATABASE check_#{host}_db;"
          #hdfs dfs -mkdir -p /user/test/hive_#{ctx.config.host}/check_metastore_tb
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          return next err, if executed then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Hive & HCat client # Check Server2', timeout: -1, callback: (ctx, next) ->
      {realm, test_user, test_password, hive_server2_host, hive_server2_port} = ctx.config.hdp
      url = "jdbc:hive2://#{hive_server2_host}:#{hive_server2_port}/default;principal=hive/#{hive_server2_host}@#{realm}"
      query = (query) -> "/usr/lib/hive/bin/beeline -u \"#{url}\" -n #{test_user} -p #{test_password} -e \"#{query}\" "
      ctx.waitIsOpen hive_server2_host, hive_server2_port, (err) ->
        host = ctx.config.host.split('.')[0]
        ctx.execute
          cmd: mkcmd.test ctx, """
          if hdfs dfs -test -d /user/test/hive_#{ctx.config.host}/check_server2_tb; then exit 2; fi
          hdfs dfs -mkdir -p /user/test/hive_#{ctx.config.host}/check_server2_tb
          echo -e 'a|1\\\\nb|2\\\\nc|3' | hdfs dfs -put - /user/test/hive_#{ctx.config.host}/check_server2_tb/data
          #{query "CREATE DATABASE IF NOT EXISTS check_#{host}_db  LOCATION '/user/test/hive_#{ctx.config.host}'"}
          #{query 'CREATE TABLE IF NOT EXISTS check_#{host}_db.check_server2_tb(col1 STRING, col2 INT);'}
          #{query 'SELECT SUM(col2) FROM check_#{host}_db.check_server2_tb;'}
          #{query 'DROP TABLE check_#{host}_db.check_server2_tb; DROP DATABASE check_#{host}_db;'}
          hdfs dfs -mkdir -p /user/test/hive_#{ctx.config.host}/check_server2_tb
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          next err, if executed then ctx.OK else ctx.PASS

      

  

















