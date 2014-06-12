---
title: 
layout: module
---

# Hive Client

    path = require 'path'
    mkcmd = require './lib/mkcmd'
    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'ryba/hadoop/hive_'
    module.exports.push 'ryba/hadoop/mapred_client'
    module.exports.push 'ryba/hadoop/yarn_client'

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
          chown -R #{hive_user.name}:#{hadoop_group.name} #{hive_conf_dir}
          chmod -R 755 #{hive_conf_dir}
          """
        , (err) ->
          next err, if configured then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Hive & HCat client # Check Metastore', timeout: -1, callback: (ctx, next) ->
      {test_user, hive_metastore_host, hive_metastore_port} = ctx.config.hdp
      ctx.waitIsOpen hive_metastore_host, hive_metastore_port, (err) ->
        host = ctx.config.host.split('.')[0]
        ctx.execute
          cmd: mkcmd.test ctx, """
          if hdfs dfs -test -f #{ctx.config.host}-hive_metastore; then exit 2; fi
          hdfs dfs -mkdir -p #{ctx.config.host}-hive/check_metastore_tb
          echo -e 'a\0011\\nb\0012\\nc\0013' | hdfs dfs -put - #{ctx.config.host}-hive/check_metastore_tb/data
          hive -e "
            CREATE DATABASE IF NOT EXISTS check_#{host}_db LOCATION '/user/#{test_user.name}/#{ctx.config.host}-hive'; \\
            USE check_#{host}_db; \\
            CREATE TABLE IF NOT EXISTS check_metastore_tb(col1 STRING, col2 INT); \\
          "
          hive -S -e "SELECT SUM(col2) FROM check_#{host}_db.check_metastore_tb;" | hdfs dfs -put - #{ctx.config.host}-hive_metastore
          hive -e "DROP TABLE check_#{host}_db.check_metastore_tb; DROP DATABASE check_#{host}_db;"
          """
          code_skipped: 2
          trap_on_error: true
        , (err, executed, stdout) ->
          return next err, if executed then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Hive & HCat client # Check Server2', timeout: -1, callback: (ctx, next) ->
      {realm, test_user, test_password, hive_server2_host, hive_server2_port} = ctx.config.hdp
      url = "jdbc:hive2://#{hive_server2_host}:#{hive_server2_port}/default;principal=hive/#{hive_server2_host}@#{realm}"
      # beeline argument s"-n #{test_user.name} -p #{test_password}" arent used with Kerberos
      query = (query) -> "/usr/lib/hive/bin/beeline -u \"#{url}\" --silent=true -e \"#{query}\" "
      ctx.waitIsOpen hive_server2_host, hive_server2_port, (err) ->
        host = ctx.config.host.split('.')[0]
        ctx.execute
          cmd: mkcmd.test ctx, """
          if hdfs dfs -test -f #{ctx.config.host}-hive_server2; then exit 2; fi
          hdfs dfs -mkdir -p #{ctx.config.host}-hive/check_server2_tb
          echo -e 'a\0011\\nb\0012\\nc\0013' | hdfs dfs -put - #{ctx.config.host}-hive/check_server2_tb/data
          #{query "CREATE DATABASE IF NOT EXISTS check_#{host}_db LOCATION '/user/#{test_user.name}/#{ctx.config.host}-hive'"}
          #{query "CREATE TABLE IF NOT EXISTS check_#{host}_db.check_server2_tb(col1 STRING, col2 INT) ;"}
          #{query "SELECT SUM(col2) FROM check_#{host}_db.check_server2_tb;"} | hdfs dfs -put - #{ctx.config.host}-hive_server2
          #{query "DROP TABLE check_#{host}_db.check_server2_tb;"}
          #{query "DROP DATABASE check_#{host}_db;"}
          """
          code_skipped: 2
          trap_on_error: true
        , (err, executed, stdout) ->
          next err, if executed then ctx.OK else ctx.PASS

      

  

















