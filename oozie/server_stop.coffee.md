---
title: 
layout: module
---

# Oozie Server Stop

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./server').configure ctx

## Stop

Execute these commands on the Oozie server host machine

    module.exports.push name: 'Oozie Server # Stop', timeout: -1, callback: (ctx, next) ->
      lifecycle.oozie_stop ctx, next
