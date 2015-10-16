
# Ganglia Collector Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/httpd'

## Configure

*   `rrdcached_user` (object|string)
    The Unix RRDtool login name or a user object (see Mecano User documentation).
*   `rrdcached_group` (object|string)
    The Unix Hue group name or a group object (see Mecano Group documentation).

Example:

```json
{
  "ganglia": {
    "rrdcached_user": {
      "name": "rrdcached", "system": true, "gid": "rrdcached", "shell": false
      "comment": "RRDtool User", "home": "/usr/lib/rrdcached"
    }
    "rrdcached_group": {
      "name": "Hue", "system": true
    }
  }
}
```

    # module.exports.push require('./index').configure

## Users & Groups

By default, the "rrdcached" package create the following entries:

```bash
cat /etc/passwd | grep rrdcached
rrdcached:x:493:493:rrdcached:/var/rrdtool/rrdcached:/sbin/nologin
cat /etc/group | grep rrdcached
rrdcached:x:493:
```

    module.exports.push name: 'Ganglia Collector # Users & Groups', handler: ->
      {rrdcached_group, rrdcached_user} = @config.ryba.ganglia
      @group rrdcached_group
      @user rrdcached_user

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

    module.exports.push name: 'Ganglia Collector # IPTables', handler: ->
      @iptables
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

    module.exports.push name: 'Ganglia Collector # Service', timeout: -1, handler: ->
      @service
        name: 'ganglia-gmetad-3.5.0-99'
        srv_name: 'gmetad'
        # action: 'stop' # Stoping here invalidate hdp-service HTTPD to restard
        startup: false
      @service
        name: 'ganglia-web-3.5.7-99'

## Init Script

Upload the "hdp-gmetad" service file into "/etc/init.d".

    module.exports.push name: 'Ganglia Collector # Init Script', timeout: -1, handler: ->
      @write
        destination: '/etc/init.d/hdp-gmetad'
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

    module.exports.push name: 'Ganglia Collector # Layout', timeout: -1, handler: ->
      @mkdir
        destination: '/usr/libexec/hdp/ganglia'

## Objects

Copy the object files provided in the HDP companion files into the
"/usr/libexec/hdp/ganglia" folder. Permissions on those file are set to "0o744".

    module.exports.push name: 'Ganglia Collector # Objects', timeout: -1, handler: (_, callback) ->
      glob "#{__dirname}/../resources/objects/*.*", (err, files) =>
        for file in files
          @upload
            source: file
            destination: "/usr/libexec/hdp/ganglia"
            mode: 0o744
        @then callback

## Fix User

RRDtool is by default runing as "nobody". In order to work, nobody need a login shell
in its user account definition.

    module.exports.push name: 'Ganglia Collector # Fix User', handler: ->
      @user
        name: 'nobody'
        shell: '/bin/bash'

## Clusters

The cluster generation follow Hortonworks guideline and generate the clusters
"HDPHistoryServer", "HDPNameNode", "HDPResourceManager", "HDPSlaves" and "HDPHBaseMaster".

    module.exports.push name: 'Ganglia Collector # Clusters', timeout: -1, handler: ->
      # On the Ganglia server, to configure the gmond collector
      @execute
        cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPHistoryServer -m"
        not_if_exists: '/etc/ganglia/hdp/HDPHistoryServer'
      @execute
        cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPNameNode -m"
        not_if_exists: '/etc/ganglia/hdp/HDPNameNode'
      @execute
        cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPResourceManager -m"
        not_if_exists: '/etc/ganglia/hdp/HDPResourceManager'
      @execute
        cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPSlaves -m"
        not_if_exists: '/etc/ganglia/hdp/HDPSlaves'
        cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPHBaseMaster -m"
        not_if_exists: '/etc/ganglia/hdp/HDPHBaseMaster'
      @execute
        cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -t"
        not_if_exists: '/etc/ganglia/hdp/gmetad.conf'

## Configuration

In order to work properly, each cluster must be updated with the "bind" property
pointing to the Ganglia master hostname.

    module.exports.push name: 'Ganglia Collector # Configuration', handler: ->
      @write
        destination: "/etc/ganglia/hdp/HDPNameNode/conf.d/gmond.master.conf"
        match: /^(.*)bind = (.*)$/mg
        replace: "$1bind = #{@config.host}"
      @write
        destination: "/etc/ganglia/hdp/HDPHistoryServer/conf.d/gmond.master.conf"
        match: /^(.*)bind = (.*)$/mg
        replace: "$1bind = #{@config.host}"
      @write
        destination: "/etc/ganglia/hdp/HDPResourceManager/conf.d/gmond.master.conf"
        match: /^(.*)bind = (.*)$/mg
        replace: "$1bind = #{@config.host}"
      @write
        destination: "/etc/ganglia/hdp/HDPSlaves/conf.d/gmond.master.conf"
        match: /^(.*)bind = (.*)$/mg
        replace: "$1bind = #{@config.host}"
      @write
        destination: "/etc/ganglia/hdp/HDPHBaseMaster/conf.d/gmond.master.conf"
        match: /^(.*)bind = (.*)$/mg
        replace: "$1bind = #{@config.host}"
      @write
        destination: "/etc/ganglia/hdp/gmetad.conf"
        match: /^(data_source.* )(.*):(\d+)$/mg
        replace: "$1#{@config.host}:$3"

## HTTPD Restart

    module.exports.push name: 'Ganglia Collector # HTTPD Restart', handler: ->
      @service
        srv_name: 'httpd'
        action: ['start', 'restart']
        not_if: (options, callback) ->
          @execute
            cmd: "curl -s http://#{@config.host}/ganglia/"
          , (err, _, stdout) ->
            callback null, !err and /Ganglia Web Frontend/.test stdout

## Start

    module.exports.push 'ryba/ganglia/collector/start'

## Check

    module.exports.push 'ryba/ganglia/collector/check'

## Dependencies

    glob = require 'glob'
