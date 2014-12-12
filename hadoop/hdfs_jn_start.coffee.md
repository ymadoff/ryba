---
title: HDFS JournalNode Start
module: ryba/hadoop/hdfs_jn_start
layout: module
---

# HDFS JournalNode Start

Start the JournalNode service. It is recommended to start a JournalNode before the
NameNodes. The "ryba/hadoop/hdfs_nn" module will wait for all the JournalNodes
to be started on the active NameNode before it check if it must be formated.

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/krb5_client/wait'
    module.exports.push require('./hdfs_jn').configure

    module.exports.push name: 'Hadoop HDFS JN # Start', label_true: 'STARTED', timeout: -1, callback: (ctx, next) ->
      lifecycle.jn_start ctx, next
