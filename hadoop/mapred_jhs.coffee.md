---
title: 
layout: module
---

# MapRed JobHistoryServer

    module.exports = []

## Configuration

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('./yarn').configure ctx
      # require('./mapred').configure ctx
      {ryba} = ctx.config
      ryba.mapred_pid_dir ?= '/var/run/hadoop-mapreduce'  # /etc/hadoop/conf/hadoop-env.sh#94
      ryba.mapred_site = ryba.mapred_site ?= {}
      # TODO
      ryba.mapred_site['mapreduce.jobhistory.http.policy'] = 'HTTPS_ONLY' # 'HTTP_ONLY' or 'HTTPS_ONLY'
      ryba.mapred_site['mapreduce.jobhistory.keytab'] ?= "/etc/security/keytabs/jhs.service.keytab"
      # Fix: src in "[DFSConfigKeys.java][keys]" and [HDP port list] mention 13562 while companion files mentions 8081
      ryba.mapred_site['mapreduce.shuffle.port'] ?= '13562'
      ryba.mapred_site['mapreduce.jobhistory.address'] ?= "#{ctx.config.host}:10020"
      ryba.mapred_site['mapreduce.jobhistory.webapp.address'] ?= "#{ctx.config.host}:19888"
      ryba.mapred_site['mapreduce.jobhistory.webapp.https.address'] ?= "#{ctx.config.host}:19889"
      ryba.mapred_site['mapreduce.jobhistory.admin.address'] ?= "#{ctx.config.host}:10033"
      # See './hadoop-mapreduce-project/hadoop-mapreduce-client/hadoop-mapreduce-client-common/src/main/java/org/apache/hadoop/mapreduce/v2/jobhistory/JHAdminConfig.java#158'
      # yarn_site['mapreduce.jobhistory.webapp.spnego-principal']
      # yarn_site['mapreduce.jobhistory.webapp.spnego-keytab-file']

## Configuration for Staging Directories

The property "yarn.app.mapreduce.am.staging-dir" is an alternative to "done-dir"
and "intermediate-done-dir".

      ryba.mapred_site['yarn.app.mapreduce.am.staging-dir'] = null
      ryba.mapred_site['mapreduce.jobhistory.done-dir'] ?= '/mr-history/done' # Directory where history files are managed by the MR JobHistory Server.
      ryba.mapred_site['mapreduce.jobhistory.intermediate-done-dir'] ?= '/mr-history/tmp' # Directory where history files are written by MapReduce jobs.


    # module.exports.push commands: 'backup', modules: 'ryba/hadoop/mapred_jhs_backup'

    # module.exports.push commands: 'check', modules: 'ryba/hadoop/mapred_jhs_check'

    module.exports.push commands: 'install', modules: [
      'ryba/hadoop/mapred_jhs_install'
      'ryba/hadoop/mapred_jhs_start'
      'ryba/hadoop/mapred_jhs_check'
    ]

    module.exports.push commands: 'start', modules: 'ryba/hadoop/mapred_jhs_start'

    module.exports.push commands: 'status', modules: 'ryba/hadoop/mapred_jhs_status'

    module.exports.push commands: 'stop', modules: 'ryba/hadoop/mapred_jhs_stop'





