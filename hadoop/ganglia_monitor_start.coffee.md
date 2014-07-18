---
title: 
layout: module
---

# Ganglia Monitor Start

Execute this command on all the nodes in your Hadoop cluster.

    module.exports = []
    module.exports.push 'masson/bootstrap/connection'
    module.exports.push 'masson/bootstrap/mecano'

    module.exports.push name: 'Ganglia Monitor # Start', callback: (ctx, next) ->
      # Doesnt work for 3 reasons
      # waitIsOpen doesnt use udp
      # waitIsOpen use bash instead of nc which doesnt work for udp (always exit 0)
      # collector = ctx.host_with_module 'ryba/hadoop/ganglia_collector'
      # ports = []
      # ports.push 8661 if ctx.has_any_modules 'ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_snn'
      # ports.push 8664 if ctx.has_any_modules 'ryba/hadoop/yarn_rm'
      # ports.push 8666 if ctx.has_any_modules 'ryba/hadoop/mapred_jhs'
      # ports.push 8660 if ctx.has_any_modules 'ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_nm'
      # ports.push 8663 if ctx.has_any_modules 'ryba/hbase/master'
      # ctx.waitIsOpen collector, ports, (err) ->
      #   return next err
      ctx.service
        name: 'ganglia-gmond-3.5.0-99'
        srv_name: 'hdp-gmond'
        action: 'start'
      , (err, stoped) ->
        next err, if stoped then ctx.OK else ctx.PASS


