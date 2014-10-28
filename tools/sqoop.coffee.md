---
title: Sqoop
module: ryba/hadoop/sqoop
layout: module
---

# Sqoop

Apache Sqoop is a tool designed for efficiently transferring bulk data between 
Apache Hadoop and structured datastores such as relational databases.

    module.exports = []

## Configuration

The module extends the "ryba/hadoop/core" module configuration.

*   `hdp.sqoop.libs`, (array, string)   
    List jar files (usually JDBC drivers) to upload into the Sqoop lib path. 
    Use the space or comma charectere to separate the paths when the value is a 
    string. This is for example used to add the Oracle JDBC driver "ojdbc6.jar" 
    which cannt be downloaded for licensing reasons.
*   `sqoop_user` (object|string)   
    The Unix Sqoop login name or a user object (see Mecano User documentation).   

Example:

```json
{
  "ryba": {
    "sqoop_user": {
      "name": "sqoop", "system": true, "gid": "hadoop"
      "comment": "Sqoop User", "home": "/var/lib/sqoop"
    },
    "libs": "./path/to/ojdbc6.jar"
  }
}
```

    module.exports.configure = (ctx) ->
      require('./core').configure ctx
      ctx.config.ryba.sqoop ?= {}
      # User
      ctx.config.ryba.sqoop_user = name: ctx.config.ryba.sqoop_user if typeof ctx.config.ryba.sqoop_user is 'string'
      ctx.config.ryba.sqoop_user ?= {}
      ctx.config.ryba.sqoop_user.name ?= 'sqoop'
      ctx.config.ryba.sqoop_user.system ?= true
      ctx.config.ryba.sqoop_user.comment ?= 'Sqoop User'
      ctx.config.ryba.sqoop_user.gid ?= 'hadoop'
      ctx.config.ryba.sqoop_user.home ?= '/var/lib/sqoop'
      # Layout
      ctx.config.ryba.sqoop_conf_dir ?= '/etc/sqoop/conf'
      # Configuration
      ctx.config.ryba.sqoop_site ?= {}
      # Libs
      ctx.config.ryba.sqoop.libs ?= []
      ctx.config.ryba.sqoop.libs = ctx.config.ryba.sqoop.libs.split /[\s,]+/ if typeof ctx.config.ryba.sqoop.libs is 'string'

    module.exports.push commands: 'install', modules: 'ryba/tools/sqoop_install'






