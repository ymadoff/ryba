
# HDP Pig Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push module.exports.configure = (ctx) ->
      require('./pig').configure ctx

## Check

Run a Pig script to test the installation once the ResourceManager is 
installed. The script will only be executed the first time it is deployed 
unless the "hdp.force_check" configuration property is set to "true".

    module.exports.push name: 'HDP Pig Check # Client', timeout: -1, callback: (ctx, next) ->
      {force_check, test_user} = ctx.config.ryba
      host = ctx.config.host.split('.')[0]
      rm = ctx.host_with_module 'ryba/hadoop/yarn_rm'
      ctx.waitIsOpen rm, 8050, (err) ->
        return next err if err
        ctx.write
          content: """
          data = LOAD '/user/#{test_user.name}/#{host}-pig_tmp/data' USING PigStorage(',') AS (text, number);
          result = foreach data generate UPPER(text), number+2;
          STORE result INTO '/user/#{test_user.name}/#{host}-pig' USING PigStorage();
          """
          destination: '/tmp/ryba-test.pig'
        , (err, written) ->
          return next err if err
          ctx.execute
            cmd: mkcmd.test ctx, """
            hdfs dfs -rm -r #{host}-pig_tmp || true
            hdfs dfs -rm -r #{host}-pig || true
            hdfs dfs -mkdir -p #{host}-pig_tmp
            echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{host}-pig_tmp/data
            pig /tmp/ryba-test.pig
            hdfs dfs -test -d /user/#{test_user.name}/#{host}-pig
            """
            not_if_exec: unless force_check then mkcmd.test ctx, "hdfs dfs -test -d #{host}-pig"
          , (err, executed) ->
            return next err if err
            next err, if executed then ctx.OK else ctx.PASS

## HCat

    module.exports.push name: 'HDP Pig Check # HCat', timeout: -1, callback: (ctx, next) ->
      {test_user, force_check} = ctx.config.ryba
      rm = ctx.host_with_module 'ryba/hadoop/yarn_rm'
      host = ctx.config.host.split('.')[0]
      query = (query) -> "hcat -e \"#{query}\" "
      db = "check_#{host}_pig_hcat"
      ctx.waitIsOpen rm, 8050, (err) ->
        return next err if err
        ctx.write
          content: """
          data = LOAD '#{db}.check_tb' USING org.apache.hive.hcatalog.pig.HCatLoader();
          agroup = GROUP data ALL;
          asum = foreach agroup GENERATE SUM(data.col2);
          STORE asum INTO '/user/#{test_user.name}/#{host}-pig_hcat' USING PigStorage();
          """
          destination: "/tmp/ryba-pig_hcat.pig"
          eof: true
        , (err) ->
          return next err if err
          ctx.execute
            cmd: mkcmd.test ctx, """
            hdfs dfs -rm -r #{host}-pig_hcat_tmp || true
            hdfs dfs -rm -r #{host}-pig_hcat || true
            hdfs dfs -mkdir -p #{host}-pig_hcat_tmp/db/check_tb
            echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{host}-pig_hcat_tmp/db/check_tb/data
            #{query "CREATE DATABASE IF NOT EXISTS #{db} LOCATION '/user/#{test_user.name}/#{host}-pig_hcat_tmp/db';"}
            #{query "CREATE TABLE IF NOT EXISTS #{db}.check_tb(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';"}
            pig -useHCatalog /tmp/ryba-pig_hcat.pig
            #{query "DROP TABLE #{db}.check_tb;"}
            #{query "DROP DATABASE #{db};"}
            hdfs dfs -rm -r #{host}-pig_hcat_tmp
            hdfs dfs -test -d #{host}-pig_hcat
            """
            not_if_exec: unless force_check then mkcmd.test ctx, "hdfs dfs -test -d #{host}-pig_hcat"
            trap_on_error: true
          , (err, executed) ->
            next err, if executed then ctx.OK else ctx.PASS

## Module Dependencies

    mkcmd = require '../lib/mkcmd'



