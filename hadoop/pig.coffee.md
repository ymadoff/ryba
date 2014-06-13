---
title: Pig
module: ryba/hadoop/pig
layout: module
---

# Pig

Apache Pig is a platform for analyzing large data sets that consists of a 
high-level language for expressing data analysis programs, coupled with 
infrastructure for evaluating these programs. The salient property of Pig 
programs is that their structure is amenable to substantial parallelization, 
which in turns enables them to handle very large data sets. 

    quote = require 'regexp-quote'
    mkcmd = require './lib/mkcmd'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/bootstrap/utils'
    module.exports.push 'ryba/hadoop/mapred_client'
    module.exports.push 'ryba/hadoop/yarn_client'

## Configuration

Pig uses the "hdfs" configuration. It also declare 2 optional properties:

*   `hdp.force_check` (string)   
    Force the execution of the check action on each run, otherwise it will
    run only on the first install. The property is shared by multiple
    modules and default to false.   
*   `pig_user` (object|string)   
    The Unix Pig login name or a user object (see Mecano User documentation).   
*   `hdp.pig_conf_dir` (string)   
    The Pig configuration directory, dont overwrite, default to "/etc/pig/conf".   

Example:

```json
{
  "hdp": {
    "pig_user": {
      "name": "pig", "system": true, "gid": "hadoop",
      "comment": "Pig User", "home": "/var/lib/sqoop"
    },
    force_check: true
  }
}
```

    module.exports.push module.exports.configure = (ctx) ->
      require('masson/commons/java').configure ctx
      require('./hdfs').configure ctx
      # User
      ctx.config.hdp.pig_user = name: ctx.config.hdp.pig_user if typeof ctx.config.hdp.pig_user is 'string'
      ctx.config.hdp.pig_user ?= {}
      ctx.config.hdp.pig_user.name ?= 'pig'
      ctx.config.hdp.pig_user.system ?= true
      ctx.config.hdp.pig_user.comment ?= 'Pig User'
      ctx.config.hdp.pig_user.gid ?= 'hadoop'
      ctx.config.hdp.pig_user.home ?= '/home/pig'
      # Layout
      ctx.config.hdp.pig_conf_dir ?= '/etc/pig/conf'

## Users & Groups

By default, the "pig" package create the following entries:

```bash
cat /etc/passwd | grep pig
pig:x:490:502:Used by Hadoop Pig service:/home/pig:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:502:yarn,mapred,hdfs,hue
```

    module.exports.push name: 'HDP Pig # Users & Groups', callback: (ctx, next) ->
      {hadoop_group, pig_user} = ctx.config.hdp
      ctx.group hadoop_group, (err, gmodified) ->
        return next err if err
        ctx.user pig_user, (err, umodified) ->
          next err, if gmodified or umodified then ctx.OK else ctx.PASS

## Install

The pig package is install.

    module.exports.push name: 'HDP Pig # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service
        name: 'pig'
      , (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Pig # Users', callback: (ctx, next) ->
      # 6th feb 2014: pig user isnt created by YUM, might change in a future HDP release
      {hadoop_group} = ctx.config.hdp
      ctx.execute
        cmd: "useradd pig -r -M -g #{hadoop_group.name} -s /bin/bash -c \"Used by Hadoop Pig service\""
        code: 0
        code_skipped: 9
      , (err, executed) ->
        next err, if executed then ctx.OK else ctx.PASS

## Configure

TODO: Generate the "pig.properties" file dynamically, be carefull, the HDP
companion file define no properties while the YUM package does.

    module.exports.push name: 'HDP Pig # Configure', callback: (ctx, next) ->
      next null, ctx.PASS

    module.exports.push name: 'HDP Pig # Env', callback: (ctx, next) ->
      {java_home} = ctx.config.java
      {hadoop_group, pig_conf_dir, pig_user} = ctx.config.hdp
      ctx.write
        source: "#{__dirname}/files/pig/pig-env.sh"
        destination: "#{pig_conf_dir}/pig-env.sh"
        local_source: true
        write: [
          match: /^JAVA_HOME=.*$/mg
          replace: java_home
        ]
        uid: pig_user.name
        gid: hadoop_group.name
        mode: 0o755
        backup: true
      , (err, rendered) ->
        next err, if rendered then ctx.OK else ctx.PASS

## Check

Run a Pig script to test the installation once the ResourceManager is 
installed. The script will only be executed the first time it is deployed 
unless the "hdp.force_check" configuration property is set to "true".

    module.exports.push name: 'HDP Pig # Check', callback: (ctx, next) ->
      {force_check, test_user} = ctx.config.hdp
      rm = ctx.host_with_module 'ryba/hadoop/yarn_rm'
      ctx.waitIsOpen rm, 8050, (err) ->
        return next err if err
        ctx.execute
          cmd: mkcmd.test ctx, """
          if hdfs dfs -test -d #{ctx.config.host}-pig; then exit 1; fi
          exit 0
          """
          code: 1
          code_skipped: 0
          not_if: force_check
        , (err, skip) ->
          return next err, ctx.PASS if err or skip
          ctx.execute
            cmd: mkcmd.test ctx, """
            hdfs dfs -rm -r #{ctx.config.host}-pig
            hdfs dfs -mkdir -p #{ctx.config.host}-pig
            echo -e 'a|1\\\\nb|2\\\\nc|3' | hdfs dfs -put - #{ctx.config.host}-pig/data
            """
          , (err, executed) ->
            return next err if err
            ctx.write
              content: """
              data = LOAD '/user/#{test_user.name}/#{ctx.config.host}-pig/data' USING PigStorage(',') AS (text, number);
              result = foreach data generate UPPER(text), number+2;
              STORE result INTO '/user/#{test_user.name}/#{ctx.config.host}-pig/result' USING PigStorage();
              """
              destination: '/tmp/test.pig'
            , (err, written) ->
              return next err if err
              ctx.execute
                cmd: mkcmd.test ctx, """
                pig /tmp/test.pig
                rm -rf /tmp/test.pig
                hdfs dfs -test -d /user/test/#{ctx.config.host}-pig/result
                """
              , (err, executed) ->
                next err, ctx.OK

    module.exports.push name: 'HDP Pig # Fix Pig', callback: (ctx, next) ->
      ctx.write
        write: [
          match: /^(\s)*slfJarVersion=.*/mg
          replace: "$1slfJarVersion=''"
        ,
          match: new RegExp quote('/usr/lib/hcatalog'), 'g'
          replace: '/usr/lib/hive-hcatalog'
        ]
        destination: '/usr/lib/pig/bin/pig'
        backup: true
      , (err, written) ->
        next err, if written then ctx.OK else ctx.PASS

    module.exports.push name: 'HDP Pig # Check HCat', callback: (ctx, next) ->
      {test_user, force_check} = ctx.config.hdp
      rm = ctx.host_with_module 'ryba/hadoop/yarn_rm'
      host = ctx.config.host.split('.')[0]
      query = (query) -> "hcat -e \"#{query}\" "
      db = "check_#{host}_pig_hcat"
      ctx.waitIsOpen rm, 8050, (err) ->
        return next err if err
        ctx.execute
          cmd: mkcmd.test ctx, """
          if hdfs dfs -test -d #{ctx.config.host}-pig_hcat; then exit 1; fi
          exit 0
          """
          code: 1
          code_skipped: 0
          not_if: force_check
        , (err, skip) ->
          return next err, ctx.PASS if err or skip
          ctx.write
            content: """
            data = LOAD '#{db}.check_tb' USING org.apache.hive.hcatalog.pig.HCatLoader();
            agroup = GROUP data ALL;
            asum = foreach agroup GENERATE SUM(data.col2);
            STORE asum INTO '/user/#{test_user.name}/#{host}-pig_hcat/result' USING PigStorage();
            """
            destination: "/tmp/#{ctx.config.host}-pig_hcat.pig"
            eof: true
          , (err) ->
            return next err if err
            ctx.execute
              cmd: mkcmd.test ctx, """
              hdfs dfs -rm -r #{host}-pig_hcat
              hdfs dfs -mkdir -p #{host}-pig_hcat/db/check_tb
              echo -e 'a\\x011\\nb\x012\\nc\\x013' | hdfs dfs -put - #{host}-pig_hcat/db/check_tb/data
              if [ $? != "0" ]; then exit 1; fi
              #{query "CREATE DATABASE IF NOT EXISTS check_#{host}_pig_hcat LOCATION '/user/#{test_user.name}/#{host}-pig_hcat/db';"}
              if [ $? != "0" ]; then exit 1; fi
              #{query "CREATE TABLE IF NOT EXISTS #{db}.check_tb(col1 STRING, col2 INT);"}
              if [ $? != "0" ]; then exit 1; fi
              pig -useHCatalog /tmp/#{ctx.config.host}-pig_hcat.pig
              if [ $? != "0" ]; then exit 1; fi
              #{query "DROP TABLE #{db}.check_tb;"}
              #{query "DROP DATABASE #{db};"}
              if [ $? != "0" ]; then exit 1; fi
              hdfs dfs -test -d #{host}-pig_hcat/result;
              """
            , (err, executed) ->
              next err, ctx.OK


