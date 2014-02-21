
path = require 'path'
mkcmd = require './lib/mkcmd'
lifecycle = require './lib/lifecycle'

module.exports = []
module.exports.push 'histi/actions/nc'
module.exports.push 'histi/hdp/hive_'
module.exports.push 'histi/hdp/mapred_client'
module.exports.push 'histi/hdp/yarn_client'

###
Example of a minimal client configuration:
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <property>
    <name>hive.metastore.kerberos.keytab.file</name>
    <value>/etc/security/keytabs/hive.service.keytab</value>
  </property>
  <property>
    <name>hive.metastore.kerberos.principal</name>
    <value>hive/_HOST@EDF.FR</value>
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
###

module.exports.push module.exports.configure = (ctx) ->
  require('../actions/nc').configure ctx
  require('./hdfs').configure ctx unless ctx.config.hdp.hdp_hdfs_done
  require('./hive_').configure ctx unless ctx.config.hdp.hdp_hive_done

###
Configure
---------

See [Hive/HCatalog Configuration Files](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.2/bk_installing_manually_book/content/rpm-chap6-3.html)
###
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

    # if hdfs dfs -test -d /user/test/hive_#{ctx.config.host}/check_hive_tb; then exit 2; fi
    # hive -e "
    #   CREATE DATABASE IF NOT EXISTS check_hive_db  LOCATION '/user/test/hive_#{ctx.config.host}'; \\
    #   USE check_hive_db; \\
    #   CREATE TABLE IF NOT EXISTS check_hive_tb(col1 STRING, col2 INT);" || exit 1
    # echo "a,1\\nb,2\\nc,3" > /tmp/check_hive;
    # hdfs dfs -mkdir -p /user/test/hive_#{ctx.config.host}/check_hive_tb
    # hdfs dfs -put /tmp/check_hive /user/test/hive_#{ctx.config.host}/check_hive_tb/data || exit 1
    # hive -e "SELECT SUM(col2) FROM check_hive_db.check_hive_tb;" || exit 1
    # hive -e "DROP TABLE check_hive_db.check_hive_tb; DROP DATABASE check_hive_db;" || exit 1
    # rm -rf /tmp/check_hive
    # hdfs dfs -touchz /user/test/hive_#{ctx.config.host}

module.exports.push name: 'HDP Hive & HCat client # Check Metastore', timeout: -1, callback: (ctx, next) ->
  {hive_metastore_host, hive_metastore_port} = ctx.config.hdp
  ctx.waitForConnection hive_metastore_host, hive_metastore_port, (err) ->
    ctx.execute
      cmd: mkcmd.test ctx, """
      if hdfs dfs -test -d /user/test/hive_#{ctx.config.host}/check_metastore_tb; then exit 2; fi
      hdfs dfs -mkdir -p /user/test/hive_#{ctx.config.host}/check_metastore_tb
      echo -e 'a|1\\\\nb|2\\\\nc|3' | hdfs dfs -put - /user/test/hive_#{ctx.config.host}/check_metastore_tb/data
      hive -e "
        CREATE DATABASE IF NOT EXISTS check_hive_db  LOCATION '/user/test/hive_#{ctx.config.host}'; \\
        USE check_hive_db; \\
        CREATE TABLE IF NOT EXISTS check_metastore_tb(col1 STRING, col2 INT); \\
      "
      hive -e "SELECT SUM(col2) FROM check_hive_db.check_metastore_tb;"
      hive -e "DROP TABLE check_hive_db.check_metastore_tb; DROP DATABASE check_hive_db;"
      #hdfs dfs -mkdir -p /user/test/hive_#{ctx.config.host}/check_metastore_tb
      """
      code_skipped: 2
    , (err, executed, stdout) ->
      return next err, if executed then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Hive & HCat client # Check Server2', timeout: -1, callback: (ctx, next) ->
  {test_user, test_password, hive_server2_host, hive_server2_port} = ctx.config.hdp
  {realm} = ctx.config.krb5_client
  url = "jdbc:hive2://#{hive_server2_host}:#{hive_server2_port}/default;principal=hive/#{hive_server2_host}@#{realm}"
  query = (query) -> "/usr/lib/hive/bin/beeline -u \"#{url}\" -n #{test_user} -p #{test_password} -e \"#{query}\" "
  ctx.waitForConnection hive_server2_host, hive_server2_port, (err) ->
    ctx.execute
      cmd: mkcmd.test ctx, """
      if hdfs dfs -test -d /user/test/hive_#{ctx.config.host}/check_server2_tb; then exit 2; fi
      hdfs dfs -mkdir -p /user/test/hive_#{ctx.config.host}/check_server2_tb
      echo -e 'a|1\\\\nb|2\\\\nc|3' | hdfs dfs -put - /user/test/hive_#{ctx.config.host}/check_server2_tb/data
      #{query "CREATE DATABASE IF NOT EXISTS check_hive_db  LOCATION '/user/test/hive_#{ctx.config.host}'"}
      #{query 'CREATE TABLE IF NOT EXISTS check_hive_db.check_server2_tb(col1 STRING, col2 INT);'}
      #{query 'SELECT SUM(col2) FROM check_hive_db.check_server2_tb;'}
      #{query 'DROP TABLE check_hive_db.check_server2_tb; DROP DATABASE check_hive_db;'}
      hdfs dfs -mkdir -p /user/test/hive_#{ctx.config.host}/check_server2_tb
      """
      code_skipped: 2
    , (err, executed, stdout) ->
      next err, if executed then ctx.OK else ctx.PASS

      

  

















