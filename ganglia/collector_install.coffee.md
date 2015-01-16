
# Ganglia Collector Install

    module.exports = []
    module.exports.push 'masson/bootstrap/'
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

    module.exports.push require('./collector').configure

## Users & Groups

By default, the "rrdcached" package create the following entries:

```bash
cat /etc/passwd | grep rrdcached
rrdcached:x:493:493:rrdcached:/var/rrdtool/rrdcached:/sbin/nologin
cat /etc/group | grep rrdcached
rrdcached:x:493:
```

    module.exports.push name: 'Ganglia Collector # Users & Groups', handler: (ctx, next) ->
      {rrdcached_group, rrdcached_user} = ctx.config.ryba.ganglia
      ctx.group rrdcached_group, (err, gmodified) ->
        return next err if err
        ctx.user rrdcached_user, (err, umodified) ->
          next err, gmodified or umodified

## IPTables

| Service          | Port  | Proto | Info                     |
|------------------|-------|-------|--------------------------|
| ganglia-gmetad   | 8649 | http   | Ganglia Collector server |
| hdp-gmetad   | 8660 |   | Ganglia Collector HDPSlaves |
| hdp-gmetad   | 8661 |   | Ganglia Collector HDPNameNode |
| hdp-gmetad   | 8663 |   | Ganglia Collector HDPHBaseMaster |
| hdp-gmetad   | 8664 |   | Ganglia Collector HDPResourceManager |
| hdp-gmetad   | 8666 |   | Ganglia Collector HDPHistoryServer |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'Ganglia Collector # IPTables', handler: (ctx, next) ->
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8649, protocol: 'tcp', state: 'NEW', comment: "Ganglia Collector Server" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8660, protocol: 'tcp', state: 'NEW', comment: "Ganglia Collector HDPSlaves" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8661, protocol: 'tcp', state: 'NEW', comment: "Ganglia Collector HDPNameNode" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8663, protocol: 'tcp', state: 'NEW', comment: "Ganglia Collector HDPHBaseMaster" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8664, protocol: 'tcp', state: 'NEW', comment: "Ganglia Collector HDPResourceManager" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8666, protocol: 'tcp', state: 'NEW', comment: "Ganglia Collector HDPHistoryServer" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Service

The packages "ganglia-gmetad-3.5.0-99" and "ganglia-web-3.5.7-99" are installed.

    module.exports.push name: 'Ganglia Collector # Service', timeout: -1, handler: (ctx, next) ->
      ctx.service [
        name: 'ganglia-gmetad-3.5.0-99'
        srv_name: 'gmetad'
        action: 'stop'
        startup: false
      ,
        name: 'ganglia-web-3.5.7-99'
      ], next

## Layout

We prepare the directory "/usr/libexec/hdp/ganglia" in which we later upload
the objects files and generate the hosts configuration.

    module.exports.push name: 'Ganglia Collector # Layout', timeout: -1, handler: (ctx, next) ->
      ctx.mkdir
        destination: '/usr/libexec/hdp/ganglia'
      , next

## Objects

Copy the object files provided in the HDP companion files into the 
"/usr/libexec/hdp/ganglia" folder. Permissions on those file are set to "0o744".

    module.exports.push name: 'Ganglia Collector # Objects', timeout: -1, handler: (ctx, next) ->
      glob "#{__dirname}/../resources/ganglia/objects/*.*", (err, files) ->
        files = for file in files then source: file, destination: "/usr/libexec/hdp/ganglia", mode: 0o744
        ctx.upload files, next

## Init Script

Upload the "hdp-gmetad" service file into "/etc/init.d".

    module.exports.push name: 'Ganglia Collector # Init Script', timeout: -1, handler: (ctx, next) ->
      ctx.write
        destination: '/etc/init.d/hdp-gmetad'
        source: "#{__dirname}/../resources/ganglia/scripts/hdp-gmetad"
        local_source: true
        match: /# chkconfig: .*/mg
        replace: '# chkconfig: 2345 20 80'
        append: '#!/bin/sh'
        mode: 0o755
      , (err, written) ->
        return next err, false unless written
        ctx.execute
          cmd: "service gmetad stop; chkconfig --del gmetad; chkconfig --add hdp-gmetad"
        , (err) ->
          next err, true

# Note: latest companion files seems to fix this
# ## Fix RRD

# There is a first bug in the HDP companion files preventing RRDtool (thus
# Ganglia) from starting. The variable "RRDCACHED_BASE_DIR" should point to 
# "/var/lib/ganglia/rrds".

#     module.exports.push name: 'Ganglia Collector # Fix RRD', handler: (ctx, next) ->
#       ctx.write
#         destination: '/usr/libexec/hdp/ganglia/gangliaLib.sh'
#         match: /^RRDCACHED_BASE_DIR=.*$/mg
#         replace: 'RRDCACHED_BASE_DIR=/var/lib/ganglia/rrds;'
#         append: 'GANGLIA_RUNTIME_DIR'
#       , next

# ## Fix permission

# The message "error collecting ganglia data (127.0.0.1:8652): fsockopen error"
# appeared on one cluster. Another cluster installed at the same time seems
# correct.

#     module.exports.push name: 'Ganglia Collector # Fix permission', handler: (ctx, next) ->
#       ctx.execute
#         cmd: 'chown -R nobody:root /var/lib/ganglia/rrds'
#       , (err, written) ->
#         next err, ctx.PASS

## Fix User

RRDtool is by default runing as "nobody". In order to work, nobody need a login shell
in its user account definition.

    module.exports.push name: 'Ganglia Collector # Fix User', handler: (ctx, next) ->
      ctx.execute
        cmd: 'usermod -s /bin/bash nobody'
      , (err, executed, stdout, stderr) ->
        next err, not /no changes/.test(stdout)

## Clusters

The cluster generation follow Hortonworks guideline and generate the clusters 
"HDPHistoryServer", "HDPNameNode", "HDPResourceManager", "HDPSlaves" and "HDPHBaseMaster".

    module.exports.push name: 'Ganglia Collector # Clusters', timeout: -1, handler: (ctx, next) ->
      cmds = []
      # On the Ganglia server, to configure the gmond collector
      cmds.push 
        cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPHistoryServer -m"
        not_if_exists: '/etc/ganglia/hdp/HDPHistoryServer'
      cmds.push
        cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPNameNode -m"
        not_if_exists: '/etc/ganglia/hdp/HDPNameNode'
      cmds.push
        cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPResourceManager -m"
        not_if_exists: '/etc/ganglia/hdp/HDPResourceManager'
      cmds.push
        cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPSlaves -m"
        not_if_exists: '/etc/ganglia/hdp/HDPSlaves'
      cmds.push
        cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -c HDPHBaseMaster -m"
        not_if_exists: '/etc/ganglia/hdp/HDPHBaseMaster'
      cmds.push
        cmd: "/usr/libexec/hdp/ganglia/setupGanglia.sh -t"
        not_if_exists: '/etc/ganglia/hdp/gmetad.conf'
      ctx.execute cmds, next

## Configuration

In order to work properly, each cluster must be updated with the "bind" property 
pointing to the Ganglia master hostname.

    module.exports.push name: 'Ganglia Collector # Configuration', handler: (ctx, next) ->
      ctx.write [
        destination: "/etc/ganglia/hdp/HDPNameNode/conf.d/gmond.master.conf"
        match: /^(.*)bind = (.*)$/mg
        replace: "$1bind = #{ctx.config.host}"
      ,
        destination: "/etc/ganglia/hdp/HDPHistoryServer/conf.d/gmond.master.conf"
        match: /^(.*)bind = (.*)$/mg
        replace: "$1bind = #{ctx.config.host}"
      ,
        destination: "/etc/ganglia/hdp/HDPResourceManager/conf.d/gmond.master.conf"
        match: /^(.*)bind = (.*)$/mg
        replace: "$1bind = #{ctx.config.host}"
      ,
        destination: "/etc/ganglia/hdp/HDPSlaves/conf.d/gmond.master.conf"
        match: /^(.*)bind = (.*)$/mg
        replace: "$1bind = #{ctx.config.host}"
      ,
        destination: "/etc/ganglia/hdp/HDPHBaseMaster/conf.d/gmond.master.conf"
        match: /^(.*)bind = (.*)$/mg
        replace: "$1bind = #{ctx.config.host}"
      ,
        destination: "/etc/ganglia/hdp/gmetad.conf"
        match: /^(data_source.* )(.*):(\d+)$/mg
        replace: "$1#{ctx.config.host}:$3"
      ], next

## HTTPD Restart

    module.exports.push name: 'Ganglia Collector # HTTPD Restart', handler: (ctx, next) ->
      ctx.service
        srv_name: 'httpd'
        action: ['start', 'restart']
        not_if: (callback) ->
          ctx.execute
            cmd: "curl -s http://#{ctx.config.host}/ganglia/"
          , (err, _, stdout) ->
            callback null, !err and /Ganglia Web Frontend/.test stdout
      , next

## Start

    module.exports.push 'ryba/ganglia/collector_start'

## Check

    module.exports.push 'ryba/ganglia/collector_check'

## Module dependencies

    request = require 'request'
    glob = require 'glob'





