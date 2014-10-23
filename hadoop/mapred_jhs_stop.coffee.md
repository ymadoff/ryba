---
title: 
layout: module
---

# MapRed JobHistoryServer Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./mapred').configure ctx

    module.exports.push name: 'Hadoop JobHistoryServer # Stop', callback: (ctx, next) ->
      lifecycle.jhs_stop ctx, next
