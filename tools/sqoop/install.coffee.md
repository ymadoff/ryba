
# Sqoop

The only declared dependency is "mysql_client" which install the MySQL JDBC
driver used by Sqoop.

    path = require 'path'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/commons/mysql_client'
    module.exports.push 'ryba/hadoop/hdfs_client'
    module.exports.push 'ryba/hadoop/yarn_client'
    module.exports.push require '../../lib/hconfigure'
    module.exports.push require '../../lib/hdp_select'
    module.exports.push require('./index').configure

## Users & Groups

By default, the "sqoop" package create the following entries:

```bash
cat /etc/passwd | grep sqoop
sqoop:x:491:502:Sqoop:/var/lib/sqoop:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:502:yarn,mapred,hdfs,hue
```

    module.exports.push name: 'Hadoop Sqoop # Users & Groups', handler: (ctx, next) ->
      {sqoop, hadoop_group} = ctx.config.ryba
      ctx.group hadoop_group, (err, gmodified) ->
        return next err if err
        ctx.user sqoop.user, (err, umodified) ->
          next err, gmodified or umodified

## Environment

Upload the "sqoop-env.sh" file into the "/etc/sqoop/conf" folder.

    module.exports.push name: 'Hadoop Sqoop # Environment', timeout: -1, handler: (ctx, next) ->
      {sqoop, hadoop_group} = ctx.config.ryba
      ctx.write
        source: "#{__dirname}/../../resources/sqoop/sqoop-env.sh"
        destination: "#{sqoop.conf_dir}/sqoop-env.sh"
        local_source: true
        write: [
           match: /^export HADOOP_HOME=.*$/m # Sqoop default is "/usr/lib/hadoop"
           replace: "export HADOOP_HOME=${HADOOP_HOME:-/usr/hdp/current/hadoop-client} # RYBA for HDP"
         ,
           match: /^export HBASE_HOME=.*$/m # Sqoop default is "/usr/lib/hbase"
           replace: "export HBASE_HOME=${HBASE_HOME:-/usr/hdp/current/hbase-client} # RYBA for HDP"
         ,
           match: /^export HIVE_HOME=.*$/m # Sqoop default is "/usr/lib/hive"
           replace: "export HIVE_HOME=${HIVE_HOME:-/usr/hdp/current/hive-server} # RYBA for HDP"
         ,
           match: /^export ZOOCFGDIR=.*$/m # Sqoop default is "/etc/zookeeper/conf"
           replace: "export ZOOCFGDIR=${ZOOCFGDIR:-/etc/zookeeper/conf} # RYBA for HDP"
         ,
           match: /^export HBASE_HOME=.*$/m # Sqoop default is "/usr/lib/hbase"
           replace: "export HBASE_HOME=${HADOOP_HOME:-/usr/lib/hbase} # RYBA for HDP"
        ]
        uid: sqoop.user.name
        gid: hadoop_group.name
        mode: 0o755
        backup: true
      .then next

## Configuration

Upload the "sqoop-site.xml" files into the "/etc/sqoop/conf" folder.

    module.exports.push name: 'Hadoop Sqoop # Configuration', timeout: -1, handler: (ctx, next) ->
      {sqoop, hadoop_group} = ctx.config.ryba
      ctx
      .hconfigure
        destination: "#{sqoop.conf_dir}/sqoop-site.xml"
        default: "#{__dirname}/../../resources/sqoop/sqoop-site.xml"
        local_default: true
        properties: sqoop.site
        uid: sqoop.user.name
        gid: hadoop_group.name
        mode: 0o755
        merge: true
      .then next

## Install

Install the Sqoop package following the [HDP instructions][install].

    module.exports.push name: 'Hadoop Sqoop # Install', timeout: -1, handler: (ctx, next) ->
      ctx
      .service
        name: 'sqoop'
      .hdp_select
        name: 'sqoop-client'
      .then next

## Mysql Connector

MySQL is by default usable by Sqoop. The driver installed after running the
"masson/commons/mysql_client" is copied into the Sqoop library folder.

    module.exports.push name: 'Hadoop Sqoop # MySQL Connector', handler: (ctx, next) ->
      # ctx.copy
      #   source: '/usr/share/java/mysql-connector-java.jar'
      #   destination: '/usr/hdp/current/sqoop-client/lib/'
      # , next
      ctx.link
        source: '/usr/share/java/mysql-connector-java.jar'
        destination: '/usr/hdp/current/sqoop-client/lib/mysql-connector-java.jar'
      , next

## Libs

Upload all the drivers present in the `hdp.sqoop.libs"` configuration property into
the Sqoop library folder.

    module.exports.push name: 'Hadoop Sqoop # Database Connector', handler: (ctx, next) ->
      {libs} = ctx.config.ryba.sqoop
      return next() unless libs.length
      uploads = for lib in libs
        source: lib
        destination: "/usr/hdp/current/sqoop-client/lib/#{path.basename lib}"
        binary: true
      ctx.upload uploads, next

## Check

Make sure the sqoop client is available on this server, using the [HDP validation
command][validate].

    module.exports.push name: 'Hadoop Sqoop # Check', handler: (ctx, next) ->
      ctx.execute
        cmd: "sqoop version | grep 'Sqoop [0-9].*'"
      , (err) ->
        next err, true

[install]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.9.1/bk_installing_manually_book/content/rpm-chap10-1.html
[validate]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.9.1/bk_installing_manually_book/content/rpm-chap10-4.html
