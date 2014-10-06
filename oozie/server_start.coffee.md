---
title: 
layout: module
---

# Oozie Server Start

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push (ctx) ->
      require('./server').configure ctx

## Start

Execute these commands on the Oozie server host machine

    module.exports.push name: 'Oozie Server # Start', timeout: -1, callback: (ctx, next) ->
      lifecycle.oozie_start ctx, linked

