
# Ganglia Monitor Install

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Dependencies

    module.exports.push 'masson/core/yum'

## Service

The package "ganglia-gmond-3.5.0-99" is installed.

    module.exports.push name: 'Ganglia Monitor # Service', timeout: -1, handler: (ctx, next) ->
      ctx.service
        name: 'ganglia-gmond-3.5.0-99'
      , next

## Layout

We prepare the directory "/usr/libexec/hdp/ganglia" in which we later upload
the objects files and generate the hosts configuration.

    module.exports.push name: 'Ganglia Monitor # Layout', timeout: -1, handler: (ctx, next) ->
      ctx.mkdir
        destination: '/usr/libexec/hdp/ganglia'
      , next

## Objects

Copy the object files provided in the HDP companion files into the
"/usr/libexec/hdp/ganglia" folder. Permissions on those file are set to "0o744".

    module.exports.push name: 'Ganglia Monitor # Objects', timeout: -1, handler: (ctx, next) ->
      glob "#{__dirname}/../../resources/ganglia/objects/*.*", (err, files) ->
        files = for file in files then source: file, destination: "/usr/libexec/hdp/ganglia", mode: 0o744
        ctx.upload files, next

## Init Script

Upload the "hdp-gmond" service file into "/etc/init.d".

    module.exports.push name: 'Ganglia Monitor # Init Script', timeout: -1, handler: (ctx, next) ->
      ctx.write
        destination: '/etc/init.d/hdp-gmond'
        source: "#{__dirname}/../../resources/ganglia/scripts/hdp-gmond"
        local_source: true
        match: /# chkconfig: .*/mg
        replace: '# chkconfig: 2345 70 40'
        append: '#!/bin/sh'
        mode: 0o755
      , (err, written) ->
        return next err, false unless written
        ctx.execute
          cmd: "service gmond start; chkconfig --add gmond; chkconfig --add hdp-gmond"
        , (err) ->
          next err, true

## Fix RRD

There is a first bug in the HDP companion files preventing RRDtool (thus
Ganglia) from starting. The variable "RRDCACHED_BASE_DIR" should point to
"/var/lib/ganglia/rrds".

    module.exports.push name: 'Ganglia Monitor # Fix RRD', handler: (ctx, next) ->
      ctx.write
        destination: '/usr/libexec/hdp/ganglia/gangliaLib.sh'
        match: /^RRDCACHED_BASE_DIR=.*$/mg
        replace: 'RRDCACHED_BASE_DIR=/var/lib/ganglia/rrds;'
        append: 'GANGLIA_RUNTIME_DIR'
      , next

## Host

Setup the Ganglia hosts. Categories are "HDPNameNode", "HDPResourceManager",
"HDPSlaves" and "HDPHBaseMaster".

    module.exports.push name: 'Ganglia Monitor # Host', timeout: -1, handler: (ctx, next) ->
      cmds = []
      # On the NameNode and SecondaryNameNode servers, to configure the gmond emitters
      if ctx.has_any_modules 'ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_snn'
        cmds.push cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPNameNode"
      # On the ResourceManager server, to configure the gmond emitters
      if ctx.has_any_modules 'ryba/hadoop/yarn_rm'
        cmds.push cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPResourceManager"
      # On the JobHistoryServer, to configure the gmond emitters
      if ctx.has_any_modules 'ryba/hadoop/mapred_jhs'
        cmds.push cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPHistoryServer"
      # On all hosts, to configure the gmond emitters
      if ctx.has_any_modules 'ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_nm'
        cmds.push cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPSlaves"
      # If HBase is installed, on the HBase Master, to configure the gmond emitter
      if ctx.has_any_modules 'ryba/hbase/master'
        cmds.push cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPHBaseMaster"
      ctx.execute cmds, next

## Configuration

Update the files generated in the "host" action with the host of the Ganglia Collector.

    module.exports.push name: 'Ganglia Monitor # Configuration', timeout: -1, handler: (ctx, next) ->
      collector = ctx.host_with_module 'ryba/ganglia/collector'
      writes = []
      if ctx.has_any_modules 'ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_snn'
        writes.push
          destination: "/etc/ganglia/hdp/HDPNameNode/conf.d/gmond.slave.conf"
          match: /^(.*)host = (.*)$/mg
          replace: "$1host = #{collector}"
      # On the ResourceManager server, to configure the gmond emitters
      if ctx.has_any_modules 'ryba/hadoop/yarn_rm'
        writes.push
          destination: "/etc/ganglia/hdp/HDPResourceManager/conf.d/gmond.slave.conf"
          match: /^(.*)host = (.*)$/mg
          replace: "$1host = #{collector}"
      # On the JobHistoryServer, to configure the gmond emitters
      if ctx.has_any_modules 'ryba/hadoop/mapred_jhs'
        writes.push
          destination: "/etc/ganglia/hdp/HDPHistoryServer/conf.d/gmond.slave.conf"
          match: /^(.*)host = (.*)$/mg
          replace: "$1host = #{collector}"
      # On all hosts, to configure the gmond emitters
      if ctx.has_any_modules 'ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_nm'
        writes.push
          destination: "/etc/ganglia/hdp/HDPSlaves/conf.d/gmond.slave.conf"
          match: /^(.*)host = (.*)$/mg
          replace: "$1host = #{collector}"
      # If HBase is installed, on the HBase Master, to configure the gmond emitter
      if ctx.has_any_modules 'ryba/hbase/master'
        writes.push
          destination: "/etc/ganglia/hdp/HDPHBaseMaster/conf.d/gmond.slave.conf"
          match: /^(.*)host = (.*)$/mg
          replace: "$1host = #{collector}"
      ctx.write writes, next

## Hadoop

Upload the "hadoop-metrics2.properties" to connect Hadoop with Ganglia.

    module.exports.push name: 'Ganglia Monitor # Hadoop', handler: (ctx, next) ->
      collector = ctx.host_with_module 'ryba/ganglia/collector'
      ctx.write
        source: "#{__dirname}/../../resources/core_hadoop/hadoop-metrics2.properties-GANGLIA"
        local_source: true
        destination: "/etc/hadoop/conf/hadoop-metrics2.properties"
        match: "TODO-GANGLIA-SERVER"
        replace: collector
      , next


## Module dependencies

    glob = require 'glob'

## Resources

Message "Failed to start /usr/sbin/gmond for cluster HDPSlaves" may indicate the
presence of the file "/var/run/ganglia/hdp/HDPSlaves/gmond.pid"
(see "/var/log/messages").
