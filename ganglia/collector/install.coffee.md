
# Ganglia Collector Install

    module.exports = header: 'Ganglia Collector', handler: ->
      {ganglia} = @config.ryba

## Users & Groups

By default, the "rrdcached" package create the following entries:

```bash
cat /etc/passwd | grep rrdcached
rrdcached:x:493:493:rrdcached:/var/rrdtool/rrdcached:/sbin/nologin
cat /etc/group | grep rrdcached
rrdcached:x:493:
```

      @system.group header: 'Group', ganglia.rrdcached_group
      @system.user header: 'User', ganglia.rrdcached_user

## IPTables

| Service        | Port | Proto | Info                                 |
|----------------|------|-------|--------------------------------------|
| ganglia-gmetad | 8649 | http  | Ganglia Collector server             |
| hdp-gmetad     | 8660 |       | Ganglia Collector HDPSlaves          |
| hdp-gmetad     | 8661 |       | Ganglia Collector HDPNameNode        |
| hdp-gmetad     | 8663 |       | Ganglia Collector HDPHBaseMaster     |
| hdp-gmetad     | 8664 |       | Ganglia Collector HDPResourceManager |
| hdp-gmetad     | 8666 |       | Ganglia Collector HDPHistoryServer   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8649, protocol: 'tcp', state: 'NEW', comment: "Ganglia Collector Server" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8660, protocol: 'tcp', state: 'NEW', comment: "Ganglia Collector HDPSlaves" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8661, protocol: 'tcp', state: 'NEW', comment: "Ganglia Collector HDPNameNode" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8663, protocol: 'tcp', state: 'NEW', comment: "Ganglia Collector HDPHBaseMaster" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8664, protocol: 'tcp', state: 'NEW', comment: "Ganglia Collector HDPResourceManager" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8666, protocol: 'tcp', state: 'NEW', comment: "Ganglia Collector HDPHistoryServer" }
        ]
        if: @config.iptables.action is 'start'

## Service

The packages "ganglia-gmetad-3.5.0-99" and "ganglia-web-3.5.7-99" are installed.

      @call header: 'Service', timeout: -1, handler: ->
        @service
          name: 'ganglia-gmetad-3.5.0-99'
          srv_name: 'gmetad'
          # action: 'stop' # Stoping here invalidate hdp-service HTTPD to restard
          startup: false
        @service
          name: 'ganglia-web-3.5.7-99'

## Init Script

Upload the "hdp-gmetad" service file into "/etc/init.d".

      @call header: 'Init Script', timeout: -1, handler: ->
        @file
          target: '/etc/init.d/hdp-gmetad'
          source: "#{__dirname}/../resources/scripts/hdp-gmetad"
          local_source: true
          match: /# chkconfig: .*/mg
          replace: '# chkconfig: 2345 20 80'
          append: '#!/bin/sh'
          mode: 0o755
          unlink: true
        @execute
          cmd: "service gmetad stop; chkconfig --del gmetad; chkconfig --add hdp-gmetad"
          if: -> @status -1

## Layout

We prepare the directory "/usr/libexec/hdp/ganglia" in which we later upload
the objects files and generate the hosts configuration.

      @system.mkdir
        header: 'Layout'
        target: '/usr/libexec/hdp/ganglia'

## Objects

Copy the object files provided in the HDP companion files into the
"/usr/libexec/hdp/ganglia" folder. Permissions on those file are set to "0o744".

      @call header: 'Objects', timeout: -1, handler: (_, callback) ->
        glob "#{__dirname}/../resources/objects/*.*", (err, files) =>
          @file.download (
            source: file
            target: "/usr/libexec/hdp/ganglia"
            mode: 0o744
          ) for file in files
          @then callback

## Fix User

RRDtool is by default runing as "nobody". In order to work, nobody need a login shell
in its user account definition.

      @system.user
        header: 'Fix User'
        name: 'nobody'
        shell: '/bin/bash'

## Clusters

The cluster generation follow Hortonworks guideline and generate the clusters
"HDPHistoryServer", "HDPNameNode", "HDPResourceManager", "HDPSlaves" and "HDPHBaseMaster".

      @call header: 'Clusters', timeout: -1, handler: ->
        # On the Ganglia server, to configure the gmond collector
        @execute
          cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPHistoryServer -m"
          unless_exists: '/etc/ganglia/hdp/HDPHistoryServer'
        @execute
          cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPNameNode -m"
          unless_exists: '/etc/ganglia/hdp/HDPNameNode'
        @execute
          cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPResourceManager -m"
          unless_exists: '/etc/ganglia/hdp/HDPResourceManager'
        @execute
          cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPSlaves -m"
          unless_exists: '/etc/ganglia/hdp/HDPSlaves'
          cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPHBaseMaster -m"
          unless_exists: '/etc/ganglia/hdp/HDPHBaseMaster'
        @execute
          cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -t"
          unless_exists: '/etc/ganglia/hdp/gmetad.conf'

## Configuration

In order to work properly, each cluster must be updated with the "bind" property
pointing to the Ganglia master hostname.

      @call header: 'Configuration', handler: ->
        @file
          target: "/etc/ganglia/hdp/HDPNameNode/conf.d/gmond.master.conf"
          match: /^(.*)bind = (.*)$/mg
          replace: "$1bind = #{@config.host}"
        @file
          target: "/etc/ganglia/hdp/HDPHistoryServer/conf.d/gmond.master.conf"
          match: /^(.*)bind = (.*)$/mg
          replace: "$1bind = #{@config.host}"
        @file
          target: "/etc/ganglia/hdp/HDPResourceManager/conf.d/gmond.master.conf"
          match: /^(.*)bind = (.*)$/mg
          replace: "$1bind = #{@config.host}"
        @file
          target: "/etc/ganglia/hdp/HDPSlaves/conf.d/gmond.master.conf"
          match: /^(.*)bind = (.*)$/mg
          replace: "$1bind = #{@config.host}"
        @file
          target: "/etc/ganglia/hdp/HDPHBaseMaster/conf.d/gmond.master.conf"
          match: /^(.*)bind = (.*)$/mg
          replace: "$1bind = #{@config.host}"
        @file
          target: "/etc/ganglia/hdp/gmetad.conf"
          match: /^(data_source.* )(.*):(\d+)$/mg
          replace: "$1#{@config.host}:$3"

## HTTPD Restart

      @call header: 'HTTPD Restart', handler: ->
        @execute
          cmd: """
          curl -s http://#{@config.host}/ganglia/ | grep 'Ganglia Web Frontend'
          """
          shy: true
          code_skipped: 1
        @service
          srv_name: 'httpd'
          action: ['start', 'restart']
          if: -> @status -1

## Dependencies

    glob = require 'glob'
