
# HDP Pig Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hadoop/yarn_rm_wait'
    module.exports.push require('./pig').configure

## Check

Run a Pig script to test the installation once the ResourceManager is 
installed. The script will only be executed the first time it is deployed 
unless the "hdp.force_check" configuration property is set to "true".

    module.exports.push name: 'Hadoop Pig Check # Client', timeout: -1, handler: (ctx, next) ->
      {force_check, user} = ctx.config.ryba
      ctx.write
        content: """
        data = LOAD '/user/#{user.name}/#{ctx.config.shortname}-pig_tmp/data' USING PigStorage(',') AS (text, number);
        result = foreach data generate UPPER(text), number+2;
        STORE result INTO '/user/#{user.name}/#{ctx.config.shortname}-pig' USING PigStorage();
        """
        destination: '/tmp/ryba-test.pig'
      , (err, written) ->
        return next err if err
        ctx.execute
          cmd: mkcmd.test ctx, """
          hdfs dfs -rm -r -skipTrash #{ctx.config.shortname}-pig_tmp || true
          hdfs dfs -rm -r -skipTrash #{ctx.config.shortname}-pig || true
          hdfs dfs -mkdir -p #{ctx.config.shortname}-pig_tmp
          echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{ctx.config.shortname}-pig_tmp/data
          pig /tmp/ryba-test.pig
          hdfs dfs -test -d /user/#{user.name}/#{ctx.config.shortname}-pig
          """
          not_if_exec: unless force_check then mkcmd.test ctx, "hdfs dfs -test -d #{ctx.config.shortname}-pig"
        , next

## HCat

    module.exports.push name: 'Hadoop Pig Check # HCat', timeout: -1, handler: (ctx, next) ->
      {user, force_check} = ctx.config.ryba
      query = (query) -> "hcat -e \"#{query}\" "
      db = "check_#{ctx.config.shortname}_pig_hcat"
      ctx.write
        content: """
        data = LOAD '#{db}.check_tb' USING org.apache.hive.hcatalog.pig.HCatLoader();
        agroup = GROUP data ALL;
        asum = foreach agroup GENERATE SUM(data.col2);
        STORE asum INTO '/user/#{user.name}/#{ctx.config.shortname}-pig_hcat' USING PigStorage();
        """
        destination: "/tmp/ryba-pig_hcat.pig"
        eof: true
      , (err) ->
        return next err if err
        ctx.execute
          cmd: mkcmd.test ctx, """
          hdfs dfs -rm -r #{ctx.config.shortname}-pig_hcat_tmp || true
          hdfs dfs -rm -r #{ctx.config.shortname}-pig_hcat || true
          hdfs dfs -mkdir -p #{ctx.config.shortname}-pig_hcat_tmp/db/check_tb
          echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{ctx.config.shortname}-pig_hcat_tmp/db/check_tb/data
          #{query "CREATE DATABASE IF NOT EXISTS #{db} LOCATION '/user/#{user.name}/#{ctx.config.shortname}-pig_hcat_tmp/db';"}
          #{query "CREATE TABLE IF NOT EXISTS #{db}.check_tb(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';"}
          pig -useHCatalog /tmp/ryba-pig_hcat.pig
          #{query "DROP TABLE #{db}.check_tb;"}
          #{query "DROP DATABASE #{db};"}
          hdfs dfs -rm -r #{ctx.config.shortname}-pig_hcat_tmp
          hdfs dfs -test -d #{ctx.config.shortname}-pig_hcat
          """
          not_if_exec: unless force_check then mkcmd.test ctx, "hdfs dfs -test -d #{ctx.config.shortname}-pig_hcat"
          trap_on_error: true
        , next

## Module Dependencies

    mkcmd = require '../lib/mkcmd'

