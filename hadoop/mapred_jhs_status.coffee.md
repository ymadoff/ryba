---
title: 
layout: module
---

# MapRed JobHistoryServer Status

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./mapred_jhs').configure

    module.exports.push name: 'Hadoop JobHistoryServer # Status', callback: (ctx, next) ->
      lifecycle.jhs_status ctx, (err, running) ->
        next err, if running then 'STARTED' else 'STOPPED'
