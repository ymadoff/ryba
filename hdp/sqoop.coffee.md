
# Sqoop


Apache Sqoop is a tool designed for efficiently transferring bulk data between 
Apache Hadoop and structured datastores such as relational databases.

At the time of this writing, HDP 2.0 install the version 1.4.4.

The only declared dependency is "mysql_client" which install the MySQL JDBC 
driver used by Sqoop.

    path = require 'path'
    module.exports = []
    module.exports.push 'phyla/tools/mysql_client'

## Configuration

The module extends the "phyla/hdp/core" module configuration.

*   `hdp.sqoop.libs`, (array, string)   
    List jar files (usually JDBC drivers) to upload into the Sqoop lib path. 
    Use the space or comma charectere to separate the paths when the value is a 
    string. This is for example used to add the Oracle JDBC driver "ojdbc6.jar" 
    which cannt be downloaded for licensing reasons.

Example:

```json
"hdp": {
  "libs": "./path/to/ojdbc6.jar"
}
```

    module.exports.push (ctx) ->
      require('./core').configure ctx
      ctx.config.hdp.sqoop ?= {}
      ctx.config.hdp.sqoop.libs ?= []
      ctx.config.hdp.sqoop.libs = ctx.config.hdp.sqoop.libs.split /,\s/ if typeof ctx.config.hdp.sqoop.libs is 'string'

## Install

Install the Sqoop package following the [HDP instructions][install].

    module.exports.push name: 'HDP Sqoop # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service
        name: 'sqoop'
      , (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

## Mysql Connector

MySQL is by default usable by Sqoop. The driver installed after running the 
"phyla/tools/mysql_client" is copied into the Sqoop library folder.

    module.exports.push name: 'HDP Sqoop # MySQL Connector', callback: (ctx, next) ->
      ctx.copy
        source: '/usr/share/java/mysql-connector-java.jar'
        destination: '/usr/lib/sqoop/lib/'
      , (err, copied) ->
        return next err, if copied then ctx.OK else ctx.PASS

## Libs

Upload all the drivers present in the `hdp.sqoop.libs"` configuration property into
the Sqoop library folder.

    module.exports.push name: 'HDP Sqoop # Database Connector', callback: (ctx, next) ->
      {libs} = ctx.config.hdp.sqoop
      return next() unless libs.length
      uploads = for lib in libs
        source: lib
        destination: "/usr/lib/sqoop/lib/#{path.basename lib}"
        binary: true
      ctx.upload uploads, (err, uploaded) ->
        next err, if uploaded then ctx.OK else ctx.PASS

## Check

Make sure the sqoop client is available on this server, using the [HDP validation
command][validate].

    module.exports.push name: 'HDP Sqoop # Check', callback: (ctx, next) ->
      ctx.execute
        cmd: "sqoop version | grep 'Sqoop [0-9].*'"
      , (err) ->
        next err, ctx.PASS

[install]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.9.1/bk_installing_manually_book/content/rpm-chap10-1.html
[validate]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.9.1/bk_installing_manually_book/content/rpm-chap10-4.html






