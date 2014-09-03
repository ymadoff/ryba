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
      ctx.config.ryba.pig_user = name: ctx.config.ryba.pig_user if typeof ctx.config.ryba.pig_user is 'string'
      ctx.config.ryba.pig_user ?= {}
      ctx.config.ryba.pig_user.name ?= 'pig'
      ctx.config.ryba.pig_user.system ?= true
      ctx.config.ryba.pig_user.comment ?= 'Pig User'
      ctx.config.ryba.pig_user.gid ?= 'hadoop'
      ctx.config.ryba.pig_user.home ?= '/home/pig'
      # Layout
      ctx.config.ryba.pig_conf_dir ?= '/etc/pig/conf'

## Users & Groups

By default, the "pig" package create the following entries:

```bash
cat /etc/passwd | grep pig
pig:x:490:502:Used by Hadoop Pig service:/home/pig:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:502:yarn,mapred,hdfs,hue
```

    module.exports.push name: 'HDP Pig # Users & Groups', callback: (ctx, next) ->
      {hadoop_group, pig_user} = ctx.config.ryba
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
      {hadoop_group} = ctx.config.ryba
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
      {hadoop_group, pig_conf_dir, pig_user} = ctx.config.ryba
      ctx.write
        source: "#{__dirname}/files/pig/pig-env.sh"
        destination: "#{pig_conf_dir}/pig-env.sh"
        local_source: true
        write: [
          match: /^JAVA_HOME=.*$/mg
          replace: "JAVA_HOME=#{java_home}"
        ]
        uid: pig_user.name
        gid: hadoop_group.name
        mode: 0o755
        backup: true
      , (err, rendered) ->
        next err, if rendered then ctx.OK else ctx.PASS

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

## Check

    module.exports.push 'ryba/hadoop/pig_check'

## Module Dependencies

    quote = require 'regexp-quote'



