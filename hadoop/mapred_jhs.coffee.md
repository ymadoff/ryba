---
title: 
layout: module
---

# MapRed JobHistoryServer

    module.exports = []

## Configuration

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('./mapred').configure ctx
      mapred_site = ctx.config.ryba.mapred_site
      mapred_site['mapreduce.jobhistory.keytab'] ?= "/etc/security/keytabs/jhs.service.keytab"
      # Fix: src in "[DFSConfigKeys.java][keys]" and [HDP port list] mention 13562 while companion files mentions 8081
      mapred_site['mapreduce.shuffle.port'] ?= '13562'
      mapred_site['mapreduce.jobhistory.address'] ?= "#{ctx.config.host}:10020"
      mapred_site['mapreduce.jobhistory.webapp.address'] ?= "#{ctx.config.host}:19888"
      mapred_site['mapreduce.jobhistory.webapp.https.address'] ?= "#{ctx.config.host}:19888"
      mapred_site['mapreduce.jobhistory.admin.address'] ?= "#{ctx.config.host}:10033"
      # See './hadoop-mapreduce-project/hadoop-mapreduce-client/hadoop-mapreduce-client-common/src/main/java/org/apache/hadoop/mapreduce/v2/jobhistory/JHAdminConfig.java#158'
      # yarn_site['mapreduce.jobhistory.webapp.spnego-principal']
      # yarn_site['mapreduce.jobhistory.webapp.spnego-keytab-file']

    # module.exports.push commands: 'backup', modules: 'ryba/hadoop/mapred_jhs_backup'

    # module.exports.push commands: 'check', modules: 'ryba/hadoop/mapred_jhs_check'

    module.exports.push commands: 'install', modules: 'ryba/hadoop/mapred_jhs_install'

    module.exports.push commands: 'start', modules: 'ryba/hadoop/mapred_jhs_start'

    module.exports.push commands: 'status', modules: 'ryba/hadoop/mapred_jhs_status'

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/mapred_jhs_stop'





