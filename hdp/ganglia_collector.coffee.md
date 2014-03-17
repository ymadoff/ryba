
# Ganglia Collector

Ganglia Collector is the server which recieve data collected on each 
host by the Ganglia Monitor agents.

    module.exports = []
    module.exports.push 'phyla/core/yum'

## Configuration

The module doesnt accept any configuration.

    module.exports.push module.exports.configure = (ctx) ->
      # nothing for now

## Service

The packages "ganglia-gmetad-3.5.0-99" and "ganglia-web-3.5.7-99" are installed.

    module.exports.push name: 'Ganglia Collector # Service', timeout: -1, callback: (ctx, next) ->
      ctx.service [
        name: 'ganglia-gmetad-3.5.0-99'
      ,
        name: 'ganglia-web-3.5.7-99'
      ], (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS

## Init Script

Upload the "hdp-gmetad" service file into "/etc/init.d".

    module.exports.push name: 'Ganglia Collector # Init Script', timeout: -1, callback: (ctx, next) ->
      ctx.upload [
        source: "#{__dirname}/files/ganglia/scripts/hdp-gmetad"
        destination: '/etc/init.d'
        mode: 0o755
      ], (err, uploaded) ->
        next err, if uploaded then ctx.OK else ctx.PASS

## Fix RRD

There is a first bug in the HDP companion files preventing RRDtool (and 
thus Ganglia) from starting. The variable "RRDCACHED_BASE_DIR" should point to 
"/var/lib/ganglia/rrds".

    module.exports.push name: 'Ganglia Collector # Fix RRD', callback: (ctx, next) ->
      ctx.write
        destination: '/usr/libexec/hdp/ganglia/gangliaLib.sh'
        match: /^RRDCACHED_BASE_DIR=.*$/mg
        replace: 'RRDCACHED_BASE_DIR=/var/lib/ganglia/rrds;'
        append: 'GANGLIA_RUNTIME_DIR'
      , (err, written) ->
        next err, if written then ctx.OK else ctx.PASS

## Fix User

RRDtool is by default runing as "nobody". In order to work, nobody need a login shell
in its user account definition.

    module.exports.push name: 'Ganglia Collector # Fix User', callback: (ctx, next) ->
      ctx.execute
        cmd: 'usermod -s /bin/bash nobody'
      , (err, executed, stdout, stderr) ->
        next err, if /no changes/.test(stdout) then ctx.PASS else ctx.OK

## Clusters

The cluster generation follow Hortonworks guideline and generate the clusters 
"HDPHistoryServer", "HDPNameNode", "HDPResourceManager", "HDPSlaves" and "HDPHBaseMaster".

    module.exports.push name: 'Ganglia Collector # Clusters', timeout: -1, callback: (ctx, next) ->
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
      ctx.execute cmds, (err, executed) ->
        next err, if executed then ctx.OK else ctx.PASS

## Configuration

In order to work properly, each cluster must be updated with the "bind" property 
pointing to the Ganglia master hostname.

    module.exports.push name: 'Ganglia Collector # Configuration', callback: (ctx, next) ->
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
      ], (err, written) ->
        next err, if written then ctx.OK else ctx.PASS







