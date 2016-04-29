
# Ganglia Monitor Install

    module.exports = handler: ->

## Service

The package "ganglia-gmond-3.5.0-99" is installed.

      @service
        header: 'Ganglia Monitor # Service'
        name: 'ganglia-gmond-3.5.0-99'
        timeout: -1

## Layout

We prepare the directory "/usr/libexec/hdp/ganglia" in which we later upload
the objects files and generate the hosts configuration.

      @mkdir
        header: 'Ganglia Monitor # Layout'
        destination: '/usr/libexec/hdp/ganglia'

## Objects

Copy the object files provided in the HDP companion files into the
"/usr/libexec/hdp/ganglia" folder. Permissions on those file are set to "0o744".

      @call
        header: 'Ganglia Monitor # Objects'
        handler: (_, callback) ->
          glob "#{__dirname}/../resources/objects/*.*", (err, files) =>
            return callback err if err
            @download (
              source: file
              destination: "/usr/libexec/hdp/ganglia"
              mode: 0o0744
            ) for file in files
            @then callback

## Init Script

Upload the "hdp-gmond" service file into "/etc/init.d".

      @call header: 'Ganglia Monitor # Init Script', timeout: -1, handler: ->
        @write
          destination: '/etc/init.d/hdp-gmond'
          source: "#{__dirname}/../resources/scripts/hdp-gmond"
          local_source: true
          match: /# chkconfig: .*/mg
          replace: '# chkconfig: 2345 70 40'
          append: '#!/bin/sh'
          mode: 0o755
        @execute
          # cmd: "service gmond start; chkconfig --add gmond; chkconfig --add hdp-gmond"
          cmd: "service gmond start; chkconfig --add hdp-gmond"
          if: -> @status -1

      @service_startup
        header: 'Ganglia Monitor # Fix Gmond'
        name: 'gmond'
        startup: false
        if_exec: '[[ rpm -qa | grep gmond ]]' # Saw a single node (front) without it on hdp 2.2.4

## Fix RRD

There is a first bug in the HDP companion files preventing RRDtool (thus
Ganglia) from starting. The variable "RRDCACHED_BASE_DIR" should point to
"/var/lib/ganglia/rrds".

      @write
        header: 'Ganglia Monitor # Fix RRD'
        destination: '/usr/libexec/hdp/ganglia/gangliaLib.sh'
        match: /^RRDCACHED_BASE_DIR=.*$/mg
        replace: 'RRDCACHED_BASE_DIR=/var/lib/ganglia/rrds;'
        append: 'GANGLIA_RUNTIME_DIR'

## Host

Setup the Ganglia hosts. Categories are "HDPNameNode", "HDPResourceManager",
"HDPSlaves" and "HDPHBaseMaster".

      @call header: 'Ganglia Monitor # Host', timeout: -1, handler: ->
        cmds = []
        # On the NameNode and SecondaryNameNode servers, to configure the gmond emitters
        if @has_any_modules 'ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_snn'
          cmds.push cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPNameNode"
        # On the ResourceManager server, to configure the gmond emitters
        if @has_any_modules 'ryba/hadoop/yarn_rm'
          cmds.push cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPResourceManager"
        # On the JobHistoryServer, to configure the gmond emitters
        if @has_any_modules 'ryba/hadoop/mapred_jhs'
          cmds.push cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPHistoryServer"
        # On all hosts, to configure the gmond emitters
        if @has_any_modules 'ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_nm'
          cmds.push cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPSlaves"
        # If HBase is installed, on the HBase Master, to configure the gmond emitter
        if @has_any_modules 'ryba/hbase/master'
          cmds.push cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPHBaseMaster"
        @execute cmds

## Configuration

Update the files generated in the "host" action with the host of the Ganglia Collector.

      @call header: 'Ganglia Monitor # Configuration', handler: ->
        collector = @host_with_module 'ryba/ganglia/collector'
        @write
          destination: "/etc/ganglia/hdp/HDPNameNode/conf.d/gmond.slave.conf"
          match: /^(.*)host = (.*)$/mg
          replace: "$1host = #{collector}"
          if: @has_any_modules 'ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_snn'
        # On the ResourceManager server, to configure the gmond emitters
        @write
          destination: "/etc/ganglia/hdp/HDPResourceManager/conf.d/gmond.slave.conf"
          match: /^(.*)host = (.*)$/mg
          replace: "$1host = #{collector}"
          if: @has_any_modules 'ryba/hadoop/yarn_rm'
        # On the JobHistoryServer, to configure the gmond emitters
        @write
          destination: "/etc/ganglia/hdp/HDPHistoryServer/conf.d/gmond.slave.conf"
          match: /^(.*)host = (.*)$/mg
          replace: "$1host = #{collector}"
          if: @has_any_modules 'ryba/hadoop/mapred_jhs'
        # On all hosts, to configure the gmond emitters
        @write
          destination: "/etc/ganglia/hdp/HDPSlaves/conf.d/gmond.slave.conf"
          match: /^(.*)host = (.*)$/mg
          replace: "$1host = #{collector}"
          if: @has_any_modules 'ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_nm'
        # If HBase is installed, on the HBase Master, to configure the gmond emitter
        @write
          destination: "/etc/ganglia/hdp/HDPHBaseMaster/conf.d/gmond.slave.conf"
          match: /^(.*)host = (.*)$/mg
          replace: "$1host = #{collector}"
          if: @has_any_modules 'ryba/hbase/master'

## Dependencies

    glob = require 'glob'

## Resources

Message "Failed to start /usr/sbin/gmond for cluster HDPSlaves" may indicate the
presence of the file "/var/run/ganglia/hdp/HDPSlaves/gmond.pid"
(see "/var/log/messages").
