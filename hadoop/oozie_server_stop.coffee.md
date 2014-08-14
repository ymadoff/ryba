---
title: 
layout: module
---

# Oozie Server Stop

    lifecycle = require './lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./oozie_server').configure ctx

## Stop

Execute these commands on the Oozie server host machine

    module.exports.push name: 'HDP Oozie Server # Stop', timeout: -1, callback: (ctx, next) ->
      return next() unless ctx.has_module 'ryba/hadoop/oozie_server'
      lifecycle.oozie_stop ctx, (err, stopped) ->
        next err, if stopped then ctx.OK else ctx.PASS
