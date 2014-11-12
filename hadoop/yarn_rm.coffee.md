---
title: 
layout: module
---

# YARN ResourceManager

    module.exports = []

    module.exports.configure = (ctx) ->
      require('./yarn').configure ctx
      {ryba} = ctx.config
      ryba.yarn_site['yarn.resourcemanager.keytab'] ?= '/etc/security/keytabs/rm.service.keytab'
      ryba.yarn_site['yarn.resourcemanager.principal'] ?= "rm/#{ryba.static_host}@#{ryba.realm}"
      ryba.yarn_site['yarn.resourcemanager.scheduler.class'] ?= 'org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler'

    # module.exports.push commands: 'backup', modules: 'ryba/hadoop/yarn_rm_backup'

    # module.exports.push commands: 'check', modules: 'ryba/hadoop/yarn_rm_check'

    module.exports.push commands: 'install', modules: 'ryba/hadoop/yarn_rm_install'

    module.exports.push commands: 'start', modules: 'ryba/hadoop/yarn_rm_start'

    module.exports.push commands: 'status', modules: 'ryba/hadoop/yarn_rm_status'

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/yarn_rm_stop'



