
# Pig

[Apache Pig](https://pig.apache.org/) is a platform for analyzing large data sets that consists of a
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
*   `pig.user` (object|string)
    The Unix Pig login name or a user object (see Mecano User documentation).
*   `hdp.pig.conf_dir` (string)
    The Pig configuration directory, dont overwrite, default to "/etc/pig/conf".

Example:

```json
{
  "ryba": {
    "pig": {
      "config": {
        "pig.cachedbag.memusage": "0.1",
        "pig.skewedjoin.reduce.memusage", "0.3"
      },
      "user": {
        "name": "pig", "system": true, "gid": "hadoop",
        "comment": "Pig User", "home": "/var/lib/sqoop"
      }
    },
    force_check: true
  }
}
```

    module.exports.configure = (ctx) ->
      # require('masson/commons/java').configure ctx
      # require('../../hadoop/hdfs').configure ctx
      pig = ctx.config.ryba.pig ?= {}
      # User
      pig.user = name: pig.user if typeof pig.user is 'string'
      pig.user ?= {}
      pig.user.name ?= 'pig'
      pig.user.system ?= true
      pig.user.comment ?= 'Pig User'
      pig.user.gid ?= ctx.config.ryba.hadoop_group
      pig.user.home ?= '/home/pig'
      # Layout
      pig.conf_dir ?= '/etc/pig/conf'
      # Configuration
      pig.config ?= {}

    module.exports.push commands: 'check', modules: 'ryba/pig/check'

    module.exports.push commands: 'install', modules: [
      'ryba/pig/install'
      'ryba/pig/check'
    ]
