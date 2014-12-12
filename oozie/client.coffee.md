---
title: 
layout: module
---

# Oozie Client

    module.exports = []

    module.exports.configure = (ctx) ->
      require('../hadoop/core').configure ctx
      {ryba} = ctx.config
      oozie_server = ctx.host_with_module 'ryba/oozie/server', true
      # Configuration
      ryba.oozie_site ?= {}
      ryba.oozie_site['oozie.base.url'] = "http://#{oozie_server}:11000/oozie"

    module.exports.push commands: 'install', modules: 'ryba/oozie/client_install'

    module.exports.push commands: 'check', modules: 'ryba/oozie/client_check'











