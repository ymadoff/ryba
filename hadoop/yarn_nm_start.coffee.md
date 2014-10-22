---
title: 
layout: module
---

# YARN NodeManager Start

    lifecycle = require '../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./yarn').configure

    module.exports.push name: 'HDP NodeManager # Wait RM', timeout: -1, callback: (ctx, next) ->
      {yarn_site} = ctx.config.ryba
      port = if yarn_site['yarn.http.policy'] is 'HTTPS_ONLY'
      then yarn_site['yarn.resourcemanager.webapp.address'].split(':')[1]
      else yarn_site['yarn.resourcemanager.webapp.https.address'].split(':')[1]
      resourcemanagers = ctx.host_with_module 'ryba/hadoop/yarn_rms'
      ctx.waitIsOpen resourcemanagers, port, (err) ->
        next err

    module.exports.push name: 'HDP NodeManager # Start Server', callback: (ctx, next) ->
      lifecycle.nm_start ctx, next
