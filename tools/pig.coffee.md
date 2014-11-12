---
title: Pig
module: ryba/tools/pig
layout: module
---

# Pig

Apache Pig is a platform for analyzing large data sets that consists of a 
high-level language for expressing data analysis programs, coupled with 
infrastructure for evaluating these programs. The salient property of Pig 
programs is that their structure is amenable to substantial parallelization, 
which in turns enables them to handle very large data sets.

    module.exports = []

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
  "ryba": {
    "pig_conf": {
      "pig.cachedbag.memusage": "0.1",
      "pig.skewedjoin.reduce.memusage", "0.3"
    }
    "pig_user": {
      "name": "pig", "system": true, "gid": "hadoop",
      "comment": "Pig User", "home": "/var/lib/sqoop"
    },
    force_check: true
  }
}
```

    module.exports.configure = (ctx) ->
      require('masson/commons/java').configure ctx
      require('../hadoop/hdfs').configure ctx
      {ryba} = ctx.config
      ryba.pig_conf ?= {}
      # User
      ryba.pig_user = name: ryba.pig_user if typeof ryba.pig_user is 'string'
      ryba.pig_user ?= {}
      ryba.pig_user.name ?= 'pig'
      ryba.pig_user.system ?= true
      ryba.pig_user.comment ?= 'Pig User'
      ryba.pig_user.gid ?= 'hadoop'
      ryba.pig_user.home ?= '/home/pig'
      # Layout
      ryba.pig_conf_dir ?= '/etc/pig/conf'

    module.exports.push commands: 'check', modules: 'ryba/tools/pig_check'

    module.exports.push commands: 'install', modules: [
      'ryba/tools/pig_install'
      'ryba/tools/pig_check'
    ]

