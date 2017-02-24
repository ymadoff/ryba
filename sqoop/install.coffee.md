
# Sqoop Install

The only declared dependency is MySQL Client which install the MySQL JDBC
driver used by Sqoop.

    module.exports = header: 'Sqoop Install', handler: ->
      {sqoop, hadoop_group} = @config.ryba

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## Users & Groups

By default, the "sqoop" package create the following entries:

```bash
cat /etc/passwd | grep sqoop
sqoop:x:491:502:Sqoop:/var/lib/sqoop:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:502:yarn,mapred,hdfs,hue
```

      @system.group hadoop_group
      @system.user sqoop.user

## Environment

Upload the "sqoop-env.sh" file into the "/etc/sqoop/conf" folder.

      @file
        header:'Sqoop Environment'
        target: "#{sqoop.conf_dir}/sqoop-env.sh"
        source: "#{__dirname}/resources/sqoop-env.sh"
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
        ]
        uid: sqoop.user.name
        gid: hadoop_group.name
        mode: 0o755
        backup: true

## Configuration

Upload the "sqoop-site.xml" files into the "/etc/sqoop/conf" folder.

      @hconfigure
        header: 'Sqoop Site'
        target: "#{sqoop.conf_dir}/sqoop-site.xml"
        source: "#{__dirname}/resources/sqoop-site.xml"
        local_source: true
        properties: sqoop.site
        uid: sqoop.user.name
        gid: hadoop_group.name
        mode: 0o755
        merge: true

## Install

Install the Sqoop package following the [HDP instructions][install].

      @call header: 'Packages', timeout: -1, handler: ->
        @service
          name: 'sqoop'
        @hdp_select
          name: 'sqoop-client'

## Mysql Connector

MySQL is by default usable by Sqoop. The driver installed after running the
"masson/commons/mysql/client" is copied into the Sqoop library folder.


      # @system.copy
      #   source: '/usr/share/java/mysql-connector-java.jar'
      #   target: '/usr/hdp/current/sqoop-client/lib/'
      # , next
      @system.link
        header: 'MySQL Connector'
        source: '/usr/share/java/mysql-connector-java.jar'
        target: '/usr/hdp/current/sqoop-client/lib/mysql-connector-java.jar'

## Libs

Upload all the drivers present in the `hdp.sqoop.libs"` configuration property into
the Sqoop library folder.

      @call
        header: 'Database Connector'
        if: -> @config.ryba.sqoop.libs.length
        handler: ->
          for lib in  @config.ryba.sqoop.libs
            @file.download
              source: lib
              target: "/usr/hdp/current/sqoop-client/lib/#{path.basename lib}"

## Check

Make sure the sqoop client is available on this server, using the [HDP validation
command][validate].

      @system.execute
        header: 'Check Version'
        cmd: "sqoop version | grep 'Sqoop [0-9].*'"

## Dependencies

    path = require 'path'

[install]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.9.1/bk_installing_manually_book/content/rpm-chap10-1.html
[validate]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.9.1/bk_installing_manually_book/content/rpm-chap10-4.html
