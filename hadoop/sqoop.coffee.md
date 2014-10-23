---
title: Sqoop
module: ryba/hadoop/sqoop
layout: module
---

# Sqoop


Apache Sqoop is a tool designed for efficiently transferring bulk data between 
Apache Hadoop and structured datastores such as relational databases.

At the time of this writing, HDP 2.0 install the version 1.4.4.

The only declared dependency is "mysql_client" which install the MySQL JDBC 
driver used by Sqoop.

    path = require 'path'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/commons/mysql_client'
    module.exports.push 'ryba/hadoop/hdfs_client'
    module.exports.push 'ryba/hadoop/yarn_client'

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

    module.exports.push (ctx) ->
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

## Users & Groups

By default, the "sqoop" package create the following entries:

```bash
cat /etc/passwd | grep sqoop
sqoop:x:491:502:Sqoop:/var/lib/sqoop:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:502:yarn,mapred,hdfs,hue
```

    module.exports.push name: 'Hadoop Sqoop # Users & Groups', callback: (ctx, next) ->
      {hadoop_group, sqoop_user} = ctx.config.ryba
      ctx.group hadoop_group, (err, gmodified) ->
        return next err if err
        ctx.user sqoop_user, (err, umodified) ->
          next err, gmodified or umodified

## Environment

Upload the "sqoop-env.sh" file into the "/etc/sqoop/conf" folder.

    module.exports.push name: 'Hadoop Sqoop # Environment', timeout: -1, callback: (ctx, next) ->
      {sqoop_conf_dir, sqoop_user, hadoop_group} = ctx.config.ryba
      ctx.write
        source: "#{__dirname}/../resources/sqoop/sqoop-env.sh"
        destination: "#{sqoop_conf_dir}/sqoop-env.sh"
        local_source: true
        uid: sqoop_user.name
        gid: hadoop_group.name
        mode: 0o755
      , next

## Configuration

Upload the "sqoop-site.xml" files into the "/etc/sqoop/conf" folder.

    module.exports.push name: 'Hadoop Sqoop # Configuration', timeout: -1, callback: (ctx, next) ->
      {sqoop_conf_dir, sqoop_user, hadoop_group, sqoop_site} = ctx.config.ryba
      ctx.hconfigure
        destination: "#{sqoop_conf_dir}/sqoop-site.xml"
        default: "#{__dirname}/../resources/sqoop/sqoop-site.xml"
        local_default: true
        properties: sqoop_site
        uid: sqoop_user.name
        gid: hadoop_group.name
        mode: 0o755
        merge: true
      , next

## Install

Install the Sqoop package following the [HDP instructions][install].

    module.exports.push name: 'Hadoop Sqoop # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service
        name: 'sqoop'
      , next

## Mysql Connector

MySQL is by default usable by Sqoop. The driver installed after running the 
"masson/commons/mysql_client" is copied into the Sqoop library folder.

    module.exports.push name: 'Hadoop Sqoop # MySQL Connector', callback: (ctx, next) ->
      ctx.copy
        source: '/usr/share/java/mysql-connector-java.jar'
        destination: '/usr/lib/sqoop/lib/'
      , next

## Libs

Upload all the drivers present in the `hdp.sqoop.libs"` configuration property into
the Sqoop library folder.

    module.exports.push name: 'Hadoop Sqoop # Database Connector', callback: (ctx, next) ->
      {libs} = ctx.config.ryba.sqoop
      return next() unless libs.length
      uploads = for lib in libs
        source: lib
        destination: "/usr/lib/sqoop/lib/#{path.basename lib}"
        binary: true
      ctx.upload uploads, next

## Check

Make sure the sqoop client is available on this server, using the [HDP validation
command][validate].

    module.exports.push name: 'Hadoop Sqoop # Check', callback: (ctx, next) ->
      ctx.execute
        cmd: "sqoop version | grep 'Sqoop [0-9].*'"
      , (err) ->
        next err, true

[install]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.9.1/bk_installing_manually_book/content/rpm-chap10-1.html
[validate]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.9.1/bk_installing_manually_book/content/rpm-chap10-4.html






