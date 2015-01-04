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
      # ryba.oozie_site['oozie.base.url'] = "http://#{oozie_server}:11000/oozie"
      server_contexts = ctx.contexts modules: 'ryba/oozie/server', require('./server').configure
      server_oozie_site = server_contexts[0].config.ryba.oozie_site
      ryba.oozie_site['oozie.base.url'] = server_oozie_site['oozie.base.url']
      ryba.oozie_site['oozie.service.HadoopAccessorService.kerberos.principal'] = server_oozie_site['oozie.service.HadoopAccessorService.kerberos.principal']

    module.exports.push commands: 'install', modules: 'ryba/oozie/client_install'

    module.exports.push commands: 'check', modules: 'ryba/oozie/client_check'











