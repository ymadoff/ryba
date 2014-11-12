---
title: HDFS DataNode Start
module: ryba/hadoop/hdfs_dn_start
layout: module
---

# HDFS DataNode Start

Start the DataNode service. It is recommended to start a DataNode after its associated 
NameNodes. The DataNode doesn't wait for any NameNode to be started. Inside a 
federated cluster, the DataNode may be dependant of multiple NameNode clusters 
and some may be inactive.

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./hdfs_dn').configure

    module.exports.push name: 'Hadoop HDFS DN # Start', callback: (ctx, next) ->
      return next new Error "Not an DataNode" unless ctx.has_module 'ryba/hadoop/hdfs_dn'
      lifecycle.dn_start ctx, next